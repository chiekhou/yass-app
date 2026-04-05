import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_manager.dart';
import '../../../../core/constants/api_config.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final TokenManager _tokenManager = TokenManager();

  // Login
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'];
    final tokens = data['tokens'];

    // Save tokens
    await _tokenManager.saveTokens(
      accessToken: tokens['access_token'],
      refreshToken: tokens['refresh_token'],
    );

    // Save user ID
    final user = User.fromJson(data['user']);
    await _tokenManager.saveUserId(user.id);

    return user;
  }

  // Register
  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? wilayaId,
    String? gender,
    int? age,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.register,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        if (phone != null) 'phone': phone,
        if (wilayaId != null) 'wilaya_id': wilayaId,
        if (gender != null) 'gender': gender,
        if (age != null) 'age': age,
      },
    );

    final data = response.data['data'];
    final tokens = data['tokens'];

    // Save tokens
    await _tokenManager.saveTokens(
      accessToken: tokens['access_token'],
      refreshToken: tokens['refresh_token'],
    );

    // Save user ID
    final user = User.fromJson(data['user']);
    await _tokenManager.saveUserId(user.id);

    return user;
  }

  // Register Partner
  Future<User> registerPartner({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String companyName,
    String? phone,
    String? registrationNumber,
    String? taxId,
    String? wilayaId,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.registerPartner,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'company_name': companyName,
        if (phone != null) 'phone': phone,
        if (registrationNumber != null) 'registration_number': registrationNumber,
        if (taxId != null) 'tax_id': taxId,
        if (wilayaId != null) 'wilaya_id': wilayaId,
      },
    );

    final data = response.data['data'];
    final tokens = data['tokens'];

    await _tokenManager.saveTokens(
      accessToken: tokens['access_token'],
      refreshToken: tokens['refresh_token'],
    );

    final user = User.fromJson(data['user']);
    await _tokenManager.saveUserId(user.id);

    return user;
  }

  // Get Current User
  Future<User?> getCurrentUser() async {
    final isLoggedIn = await _tokenManager.isLoggedIn();
    if (!isLoggedIn) return null;

    try {
      final response = await _apiClient.get(ApiConfig.me);
      return User.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }

  // Update Profile
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? wilayaId,
    String? language,
    String? avatar,
  }) async {
    final response = await _apiClient.put(
      ApiConfig.updateProfile,
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
        if (wilayaId != null) 'wilaya_id': wilayaId,
        if (language != null) 'language': language,
        if (avatar != null) 'avatar': avatar,
      },
    );

    return User.fromJson(response.data['data']);
  }

  // Update Partner Profile (company info)
  Future<PartnerProfile> updatePartnerProfile({
    String? companyName,
    String? registrationNumber,
    String? taxId,
  }) async {
    final response = await _apiClient.put(
      ApiConfig.updatePartnerProfile,
      data: {
        if (companyName != null) 'company_name': companyName,
        if (registrationNumber != null) 'registration_number': registrationNumber,
        if (taxId != null) 'tax_id': taxId,
      },
    );

    return PartnerProfile.fromJson(response.data['data']);
  }

  // Forgot Password (email)
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post(
      ApiConfig.forgotPassword,
      data: {'email': email},
    );
  }

  // Forgot Password (phone OTP)
  Future<void> forgotPasswordByPhone({required String phone}) async {
    await _apiClient.post(
      ApiConfig.forgotPasswordPhone,
      data: {'phone': phone},
    );
  }

  // Reset Password (phone OTP)
  Future<void> resetPasswordByPhone({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConfig.resetPasswordPhone,
      data: {'phone': phone, 'otp': otp, 'new_password': newPassword},
    );
  }

  // Reset Password
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _apiClient.post(
      ApiConfig.resetPassword,
      data: {
        'token': token,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  // Change Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      ApiConfig.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPassword,
      },
    );
  }

  // Logout
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.post(
          ApiConfig.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } finally {
      await _tokenManager.clearTokens();
    }
  }

  // Register with phone (no email required)
  Future<User> registerWithPhone({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? wilayaId,
    String? gender,
    int? age,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.registerPhone,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        if (wilayaId != null) 'wilaya_id': wilayaId,
        if (gender != null) 'gender': gender,
        if (age != null) 'age': age,
      },
    );

    final data = response.data['data'];
    final tokens = data['tokens'];

    await _tokenManager.saveTokens(
      accessToken: tokens['access_token'],
      refreshToken: tokens['refresh_token'],
    );

    final user = User.fromJson(data['user']);
    await _tokenManager.saveUserId(user.id);

    return user;
  }

  // Login with phone number
  Future<User> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.loginPhone,
      data: {
        'phone': phone,
        'password': password,
      },
    );

    final data = response.data['data'];
    final tokens = data['tokens'];

    await _tokenManager.saveTokens(
      accessToken: tokens['access_token'],
      refreshToken: tokens['refresh_token'],
    );

    final user = User.fromJson(data['user']);
    await _tokenManager.saveUserId(user.id);

    return user;
  }

  // Send OTP to email
  Future<void> sendEmailOtp() async {
    await _apiClient.post(ApiConfig.sendEmailOtp);
  }

  // Verify email OTP
  Future<User> verifyEmailOtp({required String otp}) async {
    await _apiClient.post(
      ApiConfig.verifyEmailOtp,
      data: {'otp': otp},
    );
    final user = await getCurrentUser();
    if (user == null) throw Exception('Impossible de récupérer le profil utilisateur');
    return user;
  }

  // Send OTP to phone
  Future<void> sendPhoneOtp() async {
    await _apiClient.post(ApiConfig.sendPhoneOtp);
  }

  // Verify phone OTP
  Future<User> verifyPhoneOtp({required String otp}) async {
    await _apiClient.post(
      ApiConfig.verifyPhoneOtp,
      data: {'otp': otp},
    );
    final user = await getCurrentUser();
    if (user == null) throw Exception('Impossible de récupérer le profil utilisateur');
    return user;
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    return await _tokenManager.isLoggedIn();
  }
}
