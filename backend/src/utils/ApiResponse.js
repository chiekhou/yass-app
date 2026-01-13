class ApiResponse {
  constructor(statusCode, data, message = "") {
    this.statusCode = statusCode;
    this.success = statusCode < 400;
    this.message = message;
    this.data = data;
  }

  static success(data, message = "Success") {
    return new ApiResponse(200, data, message);
  }

  static created(data, message = "Created successfully") {
    return new ApiResponse(201, data, message);
  }

  static noContent(message = "Deleted successfully") {
    return new ApiResponse(204, null, message);
  }

  send(res) {
    const response = {
      success: this.success,
      message: this.message,
    };

    if (this.data !== null && this.data !== undefined) {
      response.data = this.data;
    }

    return res.status(this.statusCode).json(response);
  }
}

// Pagination response helper
class PaginatedResponse extends ApiResponse {
  constructor(data, pagination, message = "Success") {
    super(200, data, message);
    this.pagination = pagination;
  }

  static paginate(data, page, limit, total, message = "Success") {
    const totalPages = Math.ceil(total / limit);
    const pagination = {
      current_page: page,
      per_page: limit,
      total_items: total,
      total_pages: totalPages,
      has_next: page < totalPages,
      has_prev: page > 1,
    };

    const response = new PaginatedResponse(data, pagination, message);
    return response;
  }

  send(res) {
    return res.status(this.statusCode).json({
      success: this.success,
      message: this.message,
      data: this.data,
      pagination: this.pagination,
    });
  }
}

module.exports = { ApiResponse, PaginatedResponse };
