# jwt_sessions
[![Gem Version](https://badge.fury.io/rb/jwt_sessions.svg)](https://badge.fury.io/rb/jwt_sessions)
[![Maintainability](https://api.codeclimate.com/v1/badges/53de11b8334933b1c0ef/maintainability)](https://codeclimate.com/github/tuwukee/jwt_sessions/maintainability)
[![Build Status](https://travis-ci.org/tuwukee/jwt_sessions.svg?branch=master)](https://travis-ci.org/tuwukee/jwt_sessions)

XSS/CSRF safe JWT auth designed for SPA

## Table of Contents

- [Synopsis](#synopsis)
- [Installation](#installation)
- [Getting Started](#getting-started)
  * [Rails integration](#rails-integration)
  * [Non-Rails usage](#non-rails-usage)
- [Configuration](#configuration)
    + [Redis](#redis)
    + [JWT encryption](#jwt-encryption)
    + [Request headers and cookies names](#request-headers-and-cookies-names)
    + [Expiration time](#expiration-time)
    + [CSRF and cookies](#csrf-and-cookies)
    + [Refresh token hijack protection](#refresh-token-hijack-protection)
- [Examples](#examples)
- [TODO](#todo)
- [Contributing](#contributing)
- [License](#license)

## Synopsis

Main goal of this gem is to provide configurable, manageable, and safe stateful sessions based on JSON Web Tokens.

It's designed to be framework agnostic yet is easily integrable so Rails integration is also available out of the box.

Core concept behind jwt_sessions is that each session is represented by a pair of tokens: access and refresh,
and a session store used to handle CSRF checks and refresh token hijacking. Default token store is based on redis
but you can freely implement your own store with whichever backend you prefer.

All tokens are encoded and decoded by [ruby-jwt](https://github.com/jwt/ruby-jwt) gem, and its reserved claim names are supported
as well as it's allowed to configure claim checks and cryptographic signing algorithms supported by it.
jwt_sessions itself uses `ext` claim and `HS256` signing by default.

## Installation

Put this line in your Gemfile

```ruby
gem 'jwt_sessions'
```

Then run

```
bundle install
```

## Getting Started

`Authorization` mixin is supposed to be included in your controllers and is used to retrieve access and refresh tokens from incoming requests and verify CSRF token if needed.

### Rails integration

Include `JWTSessions::RailsAuthorization` in your controllers, add `JWTSessions::Errors::Unauthorized` exceptions handling if needed.

```ruby
class ApplicationController < ActionController::API
  include JWTSessions::RailsAuthorization
  rescue_from JWTSessions::Errors::Unauthorized, with: :not_authorized

  private

  def not_authorized
    render json: { error: 'Not authorized' }, status: :unauthorized
  end
end
```

Specify an encryption key for JSON Web Tokens in `config/initializers/jwt_session.rb` \
It's adviced to store the key itself within the app secrets.

```ruby
JWTSessions.encryption_key = Rails.application.secrets.secret_jwt_encryption_key
```

Generate access/refresh/csrf tokens with a custom payload. \
The payload will be available in the controllers once the access (or refresh) token is authorized. \
Access/refresh tokens contain expiration time in their payload. Yet expiration times are also added to the output just in case.

```ruby
> payload = { user_id: user.id }
=> {:user_id=>1}

> session = JWTSessions::Session.new(payload: payload)
=> #<JWTSessions::Session:0x00007fbe2cce9ea0...>

> session.login
=> {:csrf=>"BmhxDRW5NAEIx...",
    :access=>"eyJhbGciOiJIUzI1NiJ9...",
    :access_expires_at=>"..."
    :refresh=>"eyJhbGciOiJIUzI1NiJ9...",
    :refresh_expires_at=>"..."}
```

You can build login controller to receive access, refresh and csrf tokens in exchange for user's login/password. \
Refresh controller - to be able to get a new access token using refresh token after access is expired. \
Here is example of a simple login controller, which returns set of tokens as a plain JSON response. \
It's also possible to set tokens as cookies in the response instead.

```ruby
class LoginController < ApplicationController
  def create
    user = User.find_by!(email: params[:email])
    if user.authenticate(params[:password])
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload)
      render json: session.login
    else
      render json: 'Invalid user', status: :unauthorized
    end
  end
end
```

Since it's not required to pass an access token when you want to perform a refresh you may need to have some data in the payload of the refresh token to allow you to construct a payload of the new access token during refresh.

```ruby
session = JWTSessions::Session.new(payload: payload, refresh_payload: refresh_payload)
```

Now you can build a refresh endpoint. To protect the endpoint use before_action `authorize_refresh_request!`. \
In the example `found_token` - is a token fetched from request headers or cookies.

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

The refresh request with headers must include `X-Refresh-Token` (header name is configurable) with refresh token.

```
X-Refresh-Token: eyJhbGciOiJIUzI1NiJ9...
POST /refresh
```

Now when there're login and refresh endpoints, you can protect the rest of your secure controllers with `before_action :authorize_access_request!`.

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
  @current_user ||= User.find(payload['user_id'])
end
```

### Non-Rails usage

You must include `JWTSessions::Authorization` module to your auth class and implement within it next methods:

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
NOTE: Since rack updates HTTP headers by using `HTTP_` prefix, upcasing and using underscores for sake of simplicity JWTSessions tokens header names are converted to rack-style in this example.

```ruby
require 'sinatra/base'

JWTSessions.access_header = 'authorization'
JWTSessions.refresh_header = 'x_refresh_token'
JWTSessions.csrf_header = 'x_csrf_token'
JWTSessions.encryption_key = 'secret key'

class SimpleApp < Sinatra::Base
  include JWTSessions::Authorization

  def request_headers
    env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
  end

  def request_cookies
    request.cookies
  end

  def request_method
    request.request_method
  end

  before do
    content_type 'application/json'
  end

  post '/login' do
    access_payload = { key: 'access value' }
    refresh_payload = { key: 'refresh value' }
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: refresh_payload)
    session.login.to_json
  end

  # POST /refresh
  # x_refresh_token: ...
  post '/refresh' do
    authorize_refresh_request!
    access_payload = { key: 'reloaded access value' }
    session = JWTSessions::Session.new(payload: access_payload, refresh_payload: payload)
    session.refresh(found_token).to_json
  end

  # GET /payload
  # authorization: Bearer ...
  get '/payload' do
    authorize_access_request!
    payload.to_json
  end

  ....
end
```

## Configuration

List of configurable settings with their default values.

##### Redis

Default token store configurations

```ruby
JWTSessions.redis_host    = '127.0.0.1'
JWTSessions.redis_port    = '6379'
JWTSessions.redis_db_name = 'jwtokens'
JWTSessions.token_prefix  = 'jwt_' # used for redis db keys
```

##### JWT encryption

```ruby
JWTSessions.algorithm = 'HS256'
```

You need to specify a secret to use for HMAC, this setting doesn't have a default value.

```ruby
JWTSessions.encryption_key = 'secret'
```

If you are using another algorithm like RSA/ECDSA/EDDSA you should specify private and public keys.

```ruby
JWTSessions.private_key = 'abcd'
JWTSessions.public_key  = 'efjh'
```

NOTE: ED25519 and HS512256 require rbnacl installation in order to make it work. \

jwt_sessions only uses `exp` claim by default when it decodes tokens, you can specify which additional claims to use by
setting `jwt_options`. You can also specify leeway to account for clock skew.

```ruby
JWTSessions.jwt_options.verify_iss = true
JWTSessions.jwt_options.verify_sub = true
JWTSessions.jwt_options.verify_iat = true
JWTSessions.jwt_options.verify_aud = true
JWTSessions.jwt_options.leeway     = 30 # seconds
```

To pass options like `sub`, `aud`, `iss`, or leeways you should specify a method called `token_claims` in your controller.

```ruby
class UsersController < ApplicationController
  before_action :authorize_access_request!
  
  def token_claims
    {
      aud: ['admin', 'staff'],
      exp_leeway: 15 # will be used instead of default leeway only for exp claim
    }
  end
end
```

Claims are also supported by `JWTSessions::Session`, you can pass `access_claims` and `refresh_claims` options in the initializer
 
##### Request headers and cookies names

Default request headers/cookies names can be re-configured

```ruby
JWTSessions.access_header  = 'Authorization'
JWTSessions.access_cookie  = 'jwt_access'
JWTSessions.refresh_header = 'X-Refresh-Token'
JWTSessions.refresh_cookie = 'jwt_refresh'
JWTSessions.csrf_header    = 'X-CSRF-Token'
```

##### Expiration time

Acces token must have a short life span, while refresh tokens can be stored for a longer time period

```ruby
JWTSessions.access_exp_time = 3600 # 1 hour in seconds
JWTSessions.refresh_exp_time = 604800 # 1 week in seconds
```

#### CSRF and cookies

In case when you use cookies as your tokens transport it gets vulnerable to CSRF. That's why both login and refresh methods of the `Session` class produce CSRF tokens for you. `Authorization` mixin expects that this token is sent with all requests except GET and HEAD in a header specified among this gem's settings (X-CSRF-Token by default). Verification will be done automatically and `Authorization` exception will be raised in case of mismatch between the token from the header and the one stored in session. \
Although you don't need to mitigate BREACH attacks it's still possible to generate a new masked token with the access token

```ruby
session = JWTSessions::Session.new
session.masked_csrf(access_token)
```

#### Refresh token hijack protection

There is a security recommendation regarding the usage of refresh tokens: only perform refresh when an access token gets expired. \
Since sessions are always defined by a pair of tokens and there can't be multiple access tokens for a single refresh token simultaneous usage of the refresh token by multiple users can be easily noticed as refresh will be perfomed before the expiration of the access token by one of the users. Because of that `refresh` method of the `Session` class supports optional block as one of its arguments which will be executed only in case of refresh being performed before the expiration of the access token.

```ruby
session = JwtSessions::Session.new(payload: payload)
session.refresh(refresh_token) { |refresh_token_uid, access_token_expiration| ... }
```

## Examples

[Rails API](test/support/dummy_api) \
[Sinatra API](test/support/dummy_sinatra_api)

## TODO

Session cleanup by uid or refresh token instance. \
Refresh token namespaces to allow centralized token cleanup per namespace (scenarios like password reset).

## Contributing

Fork & Pull Request \
RbNaCl is required for tests

## License

MIT
