# Rails dummy API

Run

```
bundle install
rake db:create
rake db:migrate
```

Run tests with

```
rake
```

Start the app with

```
rails s
```

Create a user and login with

```
POST /login
Content-Type: 'application/json'
Body
  {
    email: user's email
    password: user's password
  }
```

Response example

```
{
    "csrf": "5MSmNq2h/7fbrwpUeKLP12D+10NxcZ7TpyGl0R4LYBZxx6FM+yi3nYLgUxmVKguuF0I8nUxH6WqfItFVY0mFSA==",
    "access": "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjQxMzUwODAsImtleSI6ImJpZyBhY2Nlc3MgdmFsdWUiLCJ1aWQiOiIyYTk0Mzc2My00MTZkLTQ0ZDEtYjMyMy04MTgyYThlMjg1ODIifQ.S2MyLvdZ9et3NZSDpocIuo-QIgnG-k1B91PnCzomNTo",
    "access_expires_at": "2018-04-19 13:51:20 +0300",
    "refresh": "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjQ3MzYyODAsInJlZnJlc2hfa2V5Ijoic21hbGwgcmVmcmVzaCB2YWx1ZSIsInVpZCI6IjJlM2UwODY4LWEzODAtNDA1ZC05Nzg1LWYwYjU5YmQ5MDg1ZiJ9.dnal80gMik5h26JWgmyfFDT4Y7AWYn0CZ5wWt7qwtvI",
    "refresh_expires_at": "2018-04-26 12:51:20 +0300"
}
```

Refresh request

```
POST /refresh
Content-Type: 'application/json'
X-Refresh-Token: ...
```

Example access request

```
GET /users/1
Content-Type: 'application/json'
Authorization: Bearer ...
```

Alternatively, you could use cookies as a token transport. \
In this case you'll need to send access/refresh tokens via cookies and use CSRF tokens for all requests except GET/HEAD

```
POST /login_with_cookies
Content-Type: 'application/json'
Body
  {
    email: user's email
    password: user's password
  }
```
