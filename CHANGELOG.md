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
