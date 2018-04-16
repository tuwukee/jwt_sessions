# jwt_sessions
[![Gem Version](https://badge.fury.io/rb/jwt_sessions.svg)](https://badge.fury.io/rb/jwt_sessions)

XSS/CSRF safe JWT auth designed for SPA

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

```
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

```
class ApplicationController < ActionController::API
  include JWTSessions::RailsAuthorization
  rescue_from JWTSessions::Errors::Unauthorized, with: :not_authorized

  private

  def not_authorized
    render json: { error: 'Not authorized' }, status: :unauthorized
  end
end
```

Generate access/refresh/csrf tokens with a custom payload. \
The payload will be available in the controllers once the access (or refresh) token is authorized.

```
> payload = { user_id: user.id }
=> {:user_id=>1}

> session = JWTSessions::Session.new(payload: payload)
=> #<JWTSessions::Session:0x00007fbe2cce9ea0...>

> session.login
=> {:csrf=>"BmhxDRW5NAEIx...",
    :access=>"eyJhbGciOiJIUzI1NiJ9...",
    :refresh=>"eyJhbGciOiJIUzI1NiJ9..."}
```

You can build login controller to receive access, refresh and csrf tokens in exchange for user's login/password. \
Refresh controller - to be able to get a new access token using refresh token after access is expired. \
Here is example of a simple login controller, which returns set of tokens as a plain JSON response. \
It's also possible to set tokens as cookies in the response instead.

```
class LoginController < ApplicationController
  def create
    user = User.find_by!(email: params[:email])
    if user.authenticate(params[:password])
      payload = { user_id: user.id }
      session = JWTSessions::Session.new(payload: payload)
      render json: session.login
    else
      render json: 'Invalid email or password', status: :unauthorized
    end
  end
end
```

Now you can build a refresh endpoint. To protect the endpoint use before_action `authenticate_refresh_request!`. \
In the example `found_token` - is a token fetched from request headers or cookies.

```
class RefreshController < ApplicationController
  before_action :authenticate_refresh_request!

  def create
    session = JWTSessions::Session.new(payload: payload)
    render json: session.refresh(found_token)
  end
end
```

The refresh request with headers must include `X-Refresh-Token` (header name is configurable) with refresh token.

```
X-Refresh-Token: eyJhbGciOiJIUzI1NiJ9...
POST /refresh
```

Now when there're login and refresh endpoints, you can protect the rest of your secure controllers with `before_action :authenticate_access_request!`.

```
class UsersController < ApplicationController
  before_action :authenticate_access_request!

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

```
def current_user
  @current_user ||= User.find(payload['user_id'])
end
```

### Non-Rails usage

You must include `JWTSessions::Authorization` module to your auth class and implement within it next methods:

1. request_headers

```
def request_headers
  # must return hash-like object with request headers
end
```

2. request_cookies

```
def request_cookies
  # must return hash-like object with request cookies
end
```

3. request_method

```
def request_method
  # must return current request verb as a string in upcase, f.e. 'GET', 'HEAD', 'POST', 'PATCH', etc
end
```

Example Sinatra app

```
require 'sinatra/base'

class SimpleApp < Sinatra::Base
  include JWTSessions::Authorization

  def request_headers
    request.headers
  end

  def request_cookies
    request.cookies
  end

  def request_method
    request.request_method
  end

  post '/refresh' do
    content_type :json
    authenticate_refresh_request!
    session = JWTSessions::Session.new(payload: payload)
    session.refresh(found_token).to_json
  end

  ....
end
```

## Configuration

List of configurable settings with their default values:

```
JWTSessions.redis_host = '127.0.0.1'
JWTSessions.redis_port = '6379'
```

## TODO

Add to readme CSRF tokens usage examples, cookies usage examples, configuration description, refresh before access expiration examples, security best practices, redis/non-redis token store. \
Store jwt encryption configuration as a separate options set.

## License

MIT
