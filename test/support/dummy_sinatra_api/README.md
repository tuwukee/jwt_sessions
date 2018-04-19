# Sinatra dummy API

Run

```
bundle install
```

Start the app with

```
ruby app.rb
```

Receive the tokens with

```
POST /api/v1/login
Content-Type: 'application/json'
```

Response will contain a set of tokens and expiration times

```
{
    "csrf": "5MSmNq2h/7fbrwpUeKLP12D+10NxcZ7TpyGl0R4LYBZxx6FM+yi3nYLgUxmVKguuF0I8nUxH6WqfItFVY0mFSA==",
    "access": "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjQxMzUwODAsImtleSI6ImJpZyBhY2Nlc3MgdmFsdWUiLCJ1aWQiOiIyYTk0Mzc2My00MTZkLTQ0ZDEtYjMyMy04MTgyYThlMjg1ODIifQ.S2MyLvdZ9et3NZSDpocIuo-QIgnG-k1B91PnCzomNTo",
    "access_expires_at": "2018-04-19 13:51:20 +0300",
    "refresh": "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjQ3MzYyODAsInJlZnJlc2hfa2V5Ijoic21hbGwgcmVmcmVzaCB2YWx1ZSIsInVpZCI6IjJlM2UwODY4LWEzODAtNDA1ZC05Nzg1LWYwYjU5YmQ5MDg1ZiJ9.dnal80gMik5h26JWgmyfFDT4Y7AWYn0CZ5wWt7qwtvI",
    "refresh_expires_at": "2018-04-26 12:51:20 +0300"
}
```

GET the payload

```
GET /api/v1/payload
Content-Type: 'application/json'
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjM5ODQzMTksImtleSI6ImJpZyBhY2Nlc3MgdmFsdWUiLCJ1aWQiOiI5Yjc5NTVkYi03OTgwLTQ5YjEtODYxNy03ZDg0OThkMzdmOGYifQ.bzXH5uCH6RwkGIgo0iFcJ4U5TgeSlJh5bFqO2LV6nB4
```

Refresh the tokens

```
POST /api/v1/refreshs
Content-Type: 'application/json'
X-Refresh-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjQ1ODU1MTksImtleSI6InNtYWxsIHJlZnJlc2ggdmFsdWUiLCJ1aWQiOiI2MWIzODg5NC1kMGFiLTQ1ZDMtYWE3Ni1lOTg0NWFjNWU0MjUifQ.qNDjCDk5zRYy3iXXTTSY_2kwiwLvEOu7u4fIuOvHTVU
```
