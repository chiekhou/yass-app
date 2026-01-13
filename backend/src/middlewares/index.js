const auth = require("./auth");
const error = require("./error");
const validate = require("./validate");
const rateLimiter = require("./rateLimiter");

module.exports = {
  ...auth,
  ...error,
  validate,
  ...rateLimiter,
};
