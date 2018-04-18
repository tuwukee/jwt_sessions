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

Response will contain a set of tokens

```
{
    "csrf": "a0DD7/6qzNNxK9tjXd76g31ZHqRBc6Y7/eFLl911gcbjsxbup6YtUdCVXv7IcBuMYaW9kUMALcJYVDOFNj24Og==",
    "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjM5ODQzMTksImtleSI6ImJpZyBhY2Nlc3MgdmFsdWUiLCJ1aWQiOiI5Yjc5NTVkYi03OTgwLTQ5YjEtODYxNy03ZDg0OThkMzdmOGYifQ.bzXH5uCH6RwkGIgo0iFcJ4U5TgeSlJh5bFqO2LV6nB4",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE1MjQ1ODU1MTksImtleSI6InNtYWxsIHJlZnJlc2ggdmFsdWUiLCJ1aWQiOiI2MWIzODg5NC1kMGFiLTQ1ZDMtYWE3Ni1lOTg0NWFjNWU0MjUifQ.qNDjCDk5zRYy3iXXTTSY_2kwiwLvEOu7u4fIuOvHTVU"
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
