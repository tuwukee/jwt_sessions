# jwt_sessions
[![Gem Version](https://badge.fury.io/rb/jwt_sessions.svg)](https://badge.fury.io/rb/jwt_sessions)
[![Maintainability](https://api.codeclimate.com/v1/badges/53de11b8334933b1c0ef/maintainability)](https://codeclimate.com/github/tuwukee/jwt_sessions/maintainability)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/c86efdfca81448919ec3e1c1e48fc152)](https://www.codacy.com/app/tuwukee/jwt_sessions?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=tuwukee/jwt_sessions&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.org/tuwukee/jwt_sessions.svg?branch=master)](https://travis-ci.org/tuwukee/jwt_sessions)

XSS/CSRF safe JWT auth designed for SPA

## Table of Contents

  - [Synopsis](#synopsis)
  - [Installation](#installation)
  - [Getting Started](#getting-started)
    - [Creating a session](#creating-a-session)
    - [Rails integration](#rails-integration)
    - [Non-Rails usage](#non-rails-usage)
  - [Configuration](#configuration)
      - [Token store](#token-store)
      - [JWT signature](#jwt-signature)
      - [Request headers and cookies names](#request-headers-and-cookies-names)
      - [Expiration time](#expiration-time)
      - [Exceptions](#exceptions)
      - [CSRF and cookies](#csrf-and-cookies)
        - [Refresh with access token](#refresh-with-access-token)
      - [Refresh token hijack protection](#refresh-token-hijack-protection)
  - [Flush Sessions](#flush-sessions)
        - [Sessions namespace](#sessions-namespace)
        - [Logout](#logout)
  - [Examples](#examples)
  - [Contributing](#contributing)
  - [License](#license)

## Synopsis

The primary goal of this gem is to provide configurable, manageable, and safe stateful sessions based on JSON Web Tokens.

The gem stores JWT based sessions on the backend (currently, Redis and memory stores are supported), making it possible to manage sessions, reset passwords and logout users in a reliable and secure way.

It is designed to be framework agnostic, yet easily integrable, and Rails integration is available out of the box.

The core concept behind `jwt_sessions` is that each session is represented by a pair of tokens: `access` and `refresh`. The session store is used to handle CSRF checks and prevent refresh token hijacking. Both tokens have configurable expiration times but in general the refresh token is supposed to have a longer lifespan than the access token. The access token is used to retrieve secure resources and the refresh token is used to renew the access token once it has expired. The default token store uses Redis.

All tokens are encoded and decoded by [ruby-jwt](https://github.com/jwt/ruby-jwt) gem. Its reserved claim names are supported and it can configure claim checks and cryptographic signing algorithms supported by it.
`jwt_sessions` itself uses `ext` claim and `HS256` signing by default.


## Installation

Put this line in your Gemfile:

```ruby
gem "jwt_sessions"
```

Then run:

```
bundle install
```

## Getting Started

You should configure an encryption algorithm and specify the encryption key. By default the gem uses the `HS256` signing algorithm.

```ruby
JWTSessions.encryption_key = "secret"
```

`Authorization` mixin provides helper methods which are used to retrieve the access and refresh tokens from incoming requests and verify the CSRF token if needed. It assumes that a token can be found either in a cookie or in a header (cookie and header names are configurable). It tries to retrieve the token from headers first and then from cookies (CSRF check included) if the header check fails.

### Creating a session

Each token contains a payload with custom session info. The payload is a regular Ruby hash. \
Usually, it contains a user ID or other data which help identify the current user but the payload can be an empty hash as well.

```ruby
> payload = { user_id: user.id }
=> {:user_id=>1}
```

Generate the session with a custom payload. By default the same payload is sewn into the session's access and refresh tokens.

```ruby
> session = JWTSessions::Session.new(payload: payload)
=> #<JWTSessions::Session:0x00007fbe2cce9ea0...>
```

Sometimes it makes sense to keep different data within the payloads of the access and refresh tokens. \
The access token may contain rich data including user settings, etc., while the appropriate refresh token will include only the bare minimum which will be required to reconstruct a payload for the new access token during refresh.

```ruby
session = JWTSessions::Session.new(payload: payload, refresh_payload: refresh_payload)
```

Now we can call `login` method on the session to retrieve a set of tokens.

```ruby
> session.login
=> {:csrf=>"BmhxDRW5NAEIx...",
    :access=>"eyJhbGciOiJIUzI1NiJ9...",
    :access_expires_at=>"..."
    :refresh=>"eyJhbGciOiJIUzI1NiJ9...",
    :refresh_expires_at=>"..."}
```

Access/refresh tokens automatically contain expiration time in their payload. Yet expiration times are also added to the output just in case. \
The token's payload will be available in the controllers once the access (or refresh) token is authorized.

To perform the refresh do:

```ruby
> session.refresh(refresh_token)
=> {:csrf=>"+pk2SQrXHRo1iV1x4O...",
    :access=>"eyJhbGciOiJIUzI1...",
    :access_expires_at=>"..."}
```

Available `JWTSessions::Session.new` options:

- **payload**: a hash object with session data which will be included into an access token payload. Default is an empty hash.
- **refresh_payload**: a hash object with session data which will be included into a refresh token payload. Default is the value of the access payload.
- **access_claims**: a hash object with [JWT claims](https://github.com/jwt/ruby-jwt#support-for-reserved-claim-names) which will be validated within the access token payload. For example, `{ aud: ["admin"], verify_aud: true }` means that the token can be used only by "admin" audience. Also, the endpoint can automatically validate claims instead. See `token_claims` method.
- **refresh_claims**: a hash object with [JWT claims](https://github.com/jwt/ruby-jwt#support-for-reserved-claim-names) which will be validated within the refresh token payload.
- **namespace**: a string object which helps to group sessions by a custom criteria. For example, sessions can be grouped by user ID, making it possible to logout the user from all devices. More info [Sessions Namespace](#sessions-namespace).
- **refresh_by_access_allowed**: a boolean value. Default is false. It links access and refresh tokens (adds refresh token ID to access payload), making it possible to perform a session refresh by the last expired access token. See [Refresh with access token](#refresh-with-access-token).
- **access_exp**: an integer value. Contains an access token expiration time in seconds. The value overrides global settings. See [Expiration time](#expiration-time).
- **refresh_exp**: an integer value. Contains a refresh token expiration time in seconds. The value overrides global settings. See [Expiration time](#expiration-time).

Helper methods within `Authorization` mixin:

- **authorize_access_request!**: validates access token within the request.
- **authorize_refresh_request!**: validates refresh token within the request.
- **found_token**: a raw token found within the request.
- **payload**: a decoded token's payload.
- **claimless_payload**: a decoded token's payload without claims validation (can be used for checking data of an expired token).
- **token_claims**: the method should be defined by a developer and is expected to return a hash-like object with claims to be validated within a token's payload.

### Rails integration

Include `JWTSessions::RailsAuthorization` in your controllers and add `JWTSessions::Errors::Unauthorized` exception handling if needed.

```ruby
class ApplicationController < ActionController::API
  include JWTSessions::RailsAuthorization
  rescue_from JWTSessions::Errors::Unauthorized, with: :not_authorized

  private

  def not_authorized
    render json: { error: "Not authorized" }, status: :unauthorized
  end
end
```

Specify an encryption key for JSON Web Tokens in `config/initializers/jwt_session.rb` \
It is advisable to store the key itself in a secure way, f.e. within app credentials.

```ruby
JWTSessions.algorithm = "HS256"
JWTSessions.encryption_key = Rails.application.credentials.secret_jwt_encryption_key
```

Most of the encryption algorithms require private and public keys to sign a token. However, HMAC requires only a single key and you can use the `encryption_key` shortcut to sign the token. For other algorithms you must specify private and public keys separately.

```ruby
JWTSessions.algorithm   = "RS256"
JWTSessions.private_key = OpenSSL::PKey::RSA.generate(2048)
JWTSessions.public_key  = JWTSessions.private_key.public_key
```

You can build a login controller to receive access, refresh and CSRF tokens in exchange for the user's login/password. \
Refresh controller allows you to get a new access token using the refresh token after access is expired. \

Here is an example of a simple login controller, which returns a set of tokens as a plain JSON response. \
It is also possible to set tokens as cookies in the response instead.

```ruby
class LoginController < ApplicationController
  def create
    user = User.find_by!(email: params[:email])
    if user.authenticate(params[:password])
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload)
      render json: session.login
    else
      render json: "Invalid user", status: :unauthorized
    end
  end
end
```

Now you can build a refresh endpoint. To protect the endpoint use the before_action `authorize_refresh_request!`. \
The endpoint itself should return a renewed access token.

```ruby
class RefreshController < ApplicationController
  before_action :authorize_refresh_request!

  def create
    session = JWTSessions::Session.new(payload: access_payload)
    render json: session.refresh(found_token)
  end

  def access_payload
    # payload here stands for refresh token payload
    build_access_payload_based_on_refresh(payload)
  end
end
```

In the above example, `found_token` is a token fetched from request headers or cookies. In the context of `RefreshController` it is a refresh token. \
The refresh request with headers must include `X-Refresh-Token` (header name is configurable) with the refresh token.

```
X-Refresh-Token: eyJhbGciOiJIUzI1NiJ9...
POST /refresh
```

When there are login and refresh endpoints, you can protect the rest of your secured controllers with `before_action :authorize_access_request!`.

```ruby
class UsersController < ApplicationController
  before_action :authorize_access_request!

  def index
    ...
  end

  def show
    ...
  end
end
```

Headers must include `Authorization: Bearer` with access token.

```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
GET /users
```

The `payload` method is available to fetch encoded data from the token.

```ruby
def current_user
  @current_user ||= User.find(payload["user_id"])
end
```

Methods `authorize_refresh_request!` and `authorize_access_request!` will always try to fetch the tokens from the headers first and then from the cookies.
For the cases when an endpoint must support only one specific token transport the following authorization methods can be used instead:

```ruby
authorize_by_access_cookie!
authorize_by_access_header!
authorize_by_refresh_cookie!
authorize_by_refresh_header!
```

### Non-Rails usage

You must include `JWTSessions::Authorization` module to your auth class and within it implement the following methods:

1. request_headers

```ruby
def request_headers
  # must return hash-like object with request headers
end
```

2. request_cookies

```ruby
def request_cookies
  # must return hash-like object with request cookies
end
```

3. request_method

```ruby
def request_method
  # must return current request verb as a string in upcase, f.e. 'GET', 'HEAD', 'POST', 'PATCH', etc
end
```

Example Sinatra app. \
NOTE: Rack updates HTTP headers by using the `HTTP_` prefix, upcasing and underscores for the sake of simplicity. JWTSessions token header names are converted to the rack-style in this example.

```ruby
require "sinatra/base"

JWTSessions.access_header = "authorization"
JWTSessions.refresh_header = "x_refresh_token"
JWTSessions.csrf_header = "x_csrf_token"
JWTSessions.encryption_key = "secret key"

class SimpleApp < Sinatra::Base
  include JWTSessions::Authorization

  def request_headers
    env.inject({}) { |acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc }
  end

  def request_cookies
    request.cookies
  end

  def request_method
    request.request_method
  end

  before do
    content_type "application/json"
  end

  post "/login" do
    access_payload = { key: "access value" }
    refresh_payload = { key: "refresh value" }
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: refresh_payload)
    session.login.to_json
  end

  # POST /refresh
  # x_refresh_token: ...
  post "/refresh" do
    authorize_refresh_request!
    access_payload = { key: "reloaded access value" }
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: payload)
    session.refresh(found_token).to_json
  end

  # GET /payload
  # authorization: Bearer ...
  get "/payload" do
    authorize_access_request!
    payload.to_json
  end

  # ...
end
```

## Configuration

List of configurable settings with their default values.

##### Token store

In order to configure a token store you should set up a store adapter in a following way: `JWTSessions.token_store = :redis, { redis_url: 'redis://127.0.0.1:6379/0' }` (options can be omitted). Currently supported stores are `:redis` and `:memory`. Please note, that if you want to use Redis as a store then you should have `redis` gem listed in your Gemfile. If you do not configure the adapter explicitly, this gem will try to load `redis` and use it. Otherwise it will fall back to a `memory` adapter.

Memory store only accepts a `prefix` (used for Redis db keys). Here is a default configuration for Redis:

```ruby
JWTSessions.token_store = :redis, {
  redis_host: "127.0.0.1",
  redis_port: "6379",
  redis_db_name: "0",
  token_prefix: "jwt_"
}
```

You can also provide a Redis URL instead:

```ruby
JWTSessions.token_store = :redis, { redis_url: "redis://localhost:6397" }
```

**NOTE:** if `REDIS_URL` environment variable is set it is used automatically.

SSL, timeout, reconnect, etc. redis settings are supported:
```ruby
JWTSessions.token_store = :redis, {
  read_timeout: 1.5,
  reconnect_attempts: 10,
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}
```

If you already have a configured Redis client, you can pass it among the options to reduce opened connections to a Redis server:

```ruby
JWTSessions.token_store = :redis, {redis_client: Redis.current}
```

##### JWT signature

```ruby
JWTSessions.algorithm = "HS256"
```

You need to specify a secret to use for HMAC as this setting does not have a default value.

```ruby
JWTSessions.encryption_key = "secret"
```

If you are using another algorithm like RSA/ECDSA/EDDSA you should specify private and public keys.

```ruby
JWTSessions.private_key = "abcd"
JWTSessions.public_key  = "efjh"
```

NOTE: ED25519 and HS512256 require `rbnacl` installation in order to make it work.

jwt_sessions only uses `exp` claim by default when it decodes tokens and you can specify which additional claims to use by
setting `jwt_options`. You can also specify leeway to account for clock skew.

```ruby
JWTSessions.jwt_options[:verify_iss] = true
JWTSessions.jwt_options[:verify_sub] = true
JWTSessions.jwt_options[:verify_iat] = true
JWTSessions.jwt_options[:verify_aud] = true
JWTSessions.jwt_options[:leeway]     = 30 # seconds
```

To pass options like `sub`, `aud`, `iss`, or leeways you should specify a method called `token_claims` in your controller.

```ruby
class UsersController < ApplicationController
  before_action :authorize_access_request!

  def token_claims
    {
      aud: ["admin", "staff"],
      verify_aud: true, # can be used locally instead of a global setting
      exp_leeway: 15 # will be used instead of default leeway only for exp claim
    }
  end
end
```

Claims are also supported by `JWTSessions::Session` and you can pass `access_claims` and `refresh_claims` options in the initializer.

##### Request headers and cookies names

Default request headers/cookies names can be reconfigured.

```ruby
JWTSessions.access_header  = "Authorization"
JWTSessions.access_cookie  = "jwt_access"
JWTSessions.refresh_header = "X-Refresh-Token"
JWTSessions.refresh_cookie = "jwt_refresh"
JWTSessions.csrf_header    = "X-CSRF-Token"
```

##### Expiration time

Access token must have a short life span, while refresh tokens can be stored for a longer time period.

```ruby
JWTSessions.access_exp_time = 3600 # 1 hour in seconds
JWTSessions.refresh_exp_time = 604800 # 1 week in seconds
```

It is defined globally, but can be overridden on a session level. See `JWTSessions::Session.new` options for more info.

##### Exceptions

`JWTSessions::Errors::Error` - base class, all possible exceptions are inhereted from it. \
`JWTSessions::Errors::Malconfigured` - some required gem settings are empty, or methods are not implemented. \
`JWTSessions::Errors::InvalidPayload` - token's payload doesn't contain required keys or they are invalid. \
`JWTSessions::Errors::Unauthorized` - token can't be decoded or JWT claims are invalid. \
`JWTSessions::Errors::ClaimsVerification` - JWT claims are invalid (inherited from `JWTSessions::Errors::Unauthorized`). \
`JWTSessions::Errors::Expired` - token is expired (inherited from `JWTSessions::Errors::ClaimsVerification`).

#### CSRF and cookies

When you use cookies as your tokens transport it becomes vulnerable to CSRF. That is why both the login and refresh methods of the `Session` class produce CSRF tokens for you. `Authorization` mixin expects that this token is sent with all requests except GET and HEAD in a header specified among this gem's settings (`X-CSRF-Token` by default). Verification will be done automatically and the `Authorization` exception will be raised in case of a mismatch between the token from the header and the one stored in the session. \
Although you do not need to mitigate BREACH attacks it is still possible to generate a new masked token with the access token.

```ruby
session = JWTSessions::Session.new
session.masked_csrf(access_token)
```

##### Refresh with access token

Sometimes it is not secure enough to store the refresh tokens in web / JS clients. \
This is why you have the option to only use an access token and to not pass the refresh token to the client at all. \
Session accepts `refresh_by_access_allowed: true` setting, which links the access token to the corresponding refresh token.

Example Rails login controller, which passes an access token token via cookies and renders CSRF:

```ruby
class LoginController < ApplicationController
  def create
    user = User.find_by!(email: params[:email])
    if user.authenticate(params[:password])

      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
      tokens = session.login
      response.set_cookie(JWTSessions.access_cookie,
                          value: tokens[:access],
                          httponly: true,
                          secure: Rails.env.production?)

      render json: { csrf: tokens[:csrf] }
    else
      render json: "Invalid email or password", status: :unauthorized
    end
  end
end
```

The gem provides the ability to refresh the session by access token.

```ruby
session = JWTSessions::Session.new(payload: payload, refresh_by_access_allowed: true)
tokens  = session.refresh_by_access_payload
```

In case of token forgery and successful refresh performed by an attacker the original user will have to logout. \
To protect the endpoint use the before_action `authorize_refresh_by_access_request!`. \
Refresh should be performed once the access token is already expired and we need to use the `claimless_payload` method in order to skip JWT expiration validation (and other claims) in order to proceed.

Optionally `refresh_by_access_payload` accepts a block argument (the same way `refresh` method does).
The block will be called if the refresh action is performed before the access token is expired.
Thereby it's possible to prohibit users from making refresh calls while their access token is still active.

```ruby
tokens = session.refresh_by_access_payload do
  # here goes malicious activity alert
  raise JWTSessions::Errors::Unauthorized, "Refresh action is performed before the expiration of the access token."
end
```

Example Rails refresh by access controller with cookies as token transport:

```ruby
class RefreshController < ApplicationController
  before_action :authorize_refresh_by_access_request!

  def create
    session = JWTSessions::Session.new(payload: claimless_payload, refresh_by_access_allowed: true)
    tokens  = session.refresh_by_access_payload
    response.set_cookie(JWTSessions.access_cookie,
                        value: tokens[:access],
                        httponly: true,
                        secure: Rails.env.production?)

    render json: { csrf: tokens[:csrf] }
  end
end

```

For the cases when an endpoint must support only one specific token transport the following auth methods can be used instead:

```ruby
authorize_refresh_by_access_cookie!
authorize_refresh_by_access_header!
```

#### Refresh token hijack protection

There is a security recommendation regarding the usage of refresh tokens: only perform refresh when an access token expires. \
Sessions are always defined by a pair of tokens and there cannot be multiple access tokens for a single refresh token. Simultaneous usage of the refresh token by multiple users can be easily noticed as refresh will be performed before the expiration of the access token by one of the users. As a result, `refresh` method of the `Session` class supports an optional block as one of its arguments which will be executed only in case of refresh being performed before the expiration of the access token.

```ruby
session = JwtSessions::Session.new(payload: payload)
session.refresh(refresh_token) { |refresh_token_uid, access_token_expiration| ... }
```

## Flush Sessions

Flush a session by its refresh token. The method returns number of flushed sessions:

```ruby
session = JWTSessions::Session.new
tokens = session.login
session.flush_by_token(tokens[:refresh]) # => 1
```

Flush a session by its access token:

```ruby
session = JWTSessions::Session.new(refresh_by_access_allowed: true)
tokens = session.login
session.flush_by_access_payload
# or
session = JWTSessions::Session.new(refresh_by_access_allowed: true, payload: payload)
session.flush_by_access_payload
```

Or by refresh token UID:

```ruby
session.flush_by_uid(uid) # => 1
```

##### Sessions namespace

It's possible to group sessions by custom namespaces:

```ruby
session = JWTSessions::Session.new(namespace: "account-1")
```

Selectively flush sessions by namespace:

```ruby
session = JWTSessions::Session.new(namespace: "ie-sessions")
session.flush_namespaced # will flush all sessions which belong to the same namespace
```

Selectively flush one single session inside a namespace by its access token:

```ruby
session = JWTSessions::Session.new(namespace: "ie-sessions", payload: payload)
session.flush_by_access_payload # will flush a specific session which belongs to an existing namespace
```

Flush access tokens only:

```ruby
session = JWTSessions::Session.new(namespace: "ie-sessions")
session.flush_namespaced_access_tokens # will flush all access tokens which belong to the same namespace, but will keep refresh tokens
```

Force flush of all app sessions:

```ruby
JWTSessions::Session.flush_all
```

##### Logout

To logout you need to remove both access and refresh tokens from the store. \
Flush sessions methods can be used to perform logout. \
Refresh token or refresh token UID is required to flush a session. \
To logout with an access token, `refresh_by_access_allowed` should be set to true on access token creation. If logout by access token is allowed it is recommended to ignore the expiration claim and to allow to logout with the expired access token.

## Examples

[Rails API](test/support/dummy_api) \
[Sinatra API](test/support/dummy_sinatra_api)

You can use a mixed approach for the cases when you would like to store an access token in localStorage and refresh token in HTTP-only secure cookies. \
Rails controllers setup example:

```ruby
class LoginController < ApplicationController
  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])

      payload = { user_id: user.id, role: user.role, permissions: user.permissions }
      refresh_payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload, refresh_payload: refresh_payload)
      tokens = session.login
      response.set_cookie(JWTSessions.refresh_cookie,
                          value: tokens[:refresh],
                          httponly: true,
                          secure: Rails.env.production?)

      render json: { access: tokens[:access], csrf: tokens[:csrf] }
    else
      render json: "Cannot login", status: :unauthorized
    end
  end
end

class RefreshController < ApplicationController
  before_action :authorize_refresh_request!

  def create
    tokens = JWTSessions::Session.new(payload: access_payload).refresh(found_token)
    render json: { access: tokens[:access], csrf: tokens[:csrf] }
  end

  def access_payload
    user = User.find_by!(email: payload["user_id"])
    { user_id: user.id, role: user.role, permissions: user.permissions }
  end
end

class ResourcesController < ApplicationController
  before_action :authorize_access_request!
  before_action :validate_role_and_permissions_from_payload

  # ...
end
```

## Contributing

Fork & Pull Request. \
RbNaCl and sodium cryptographic library are required for tests.

For MacOS see [these instructions](http://macappstore.org/libsodium/). \
For example, with Homebrew:

```
brew install libsodium
```

## License

MIT
