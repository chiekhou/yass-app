const auth = require("./auth");
const error = require("./error");
const validate = require("./validate");
const rateLimiter = require("./rateLimiter");
const partner = require("./partner");

module.exports = {
  ...auth,
  ...error,
  validate,
  ...rateLimiter,
  ...partner,
};
