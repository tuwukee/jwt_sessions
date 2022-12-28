## 3.0.1 (December 28, 2022)

Support:

- fix bug with expire/expireat

## 3.0.0 (December 27, 2022)

Features:

- replace `redis` with `redis-client`
- add `pool_size` setting to support concurrency within `redis-client`'s connection pool

Support:

- upgrade `jwt` to 2.6 in dependencies

## 2.7.4 (August 31, 2022)

Support:

- compatibility with redis 5.0

## 2.7.3 (August 26, 2022)

Support:

- compatibility with jwt 2.5
- add rspec to development deps

## 2.7.2 (January 24, 2022)

Bugfixes:

- 2.7.1 version didn't include the correct patch

## 2.7.1 (January 22, 2022)

Bugfixes:

- Correctly init namespaced refresh tokens when fetching all tokens from Redis

## 2.7.0 (October 05, 2021)

Features:

- added redis_client setting to JWTSessions::StoreAdapters::RedisStoreAdapter

## 2.6.0 (June 01, 2021)

Features:

- added support for all Redis settings

Support:

- updated jwt to '>= 2.2.3'
- switched to redis scan when looking for keys
- removed extra gems from gemspec deps
- updated gems in dummy apps

## 2.5.2 (July 06, 2020)

Bugfixes:

- fixed `Using the last argument as keyword parameters is deprecated;` warnings

## 2.5.1 (April 20, 2020)

Features:

- added changelog

Bugfixes:

- fixed double exp key in payload

Support:

- moved decode error text to a constant within token class

## 2.5.0 (April 12, 2020)

Features:

- added new error class `JWTSessions::Errors::Expired`

## 2.4.3 (September 19, 2019)

Bugfixes:

- fixed lookup for refresh token for namespaced sessions

Support:

- updated sqlite to ~> 1.4 in `dummy_api`
- added 2.6.3 Ruby to CI
