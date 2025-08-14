## Mudmouth

Mudmouth is a network diagnostic library for capturing requests securely on iOS.

### Usage

- Capturing HTTP requests
- Capturing HTTPS requests with MitM

### Requirements

- iOS 16.x
- Xcode 16.x
- fastlane

## Service of Games

### [Splatoon 2](https://app.splatoon2.nintendo.net/)

|              |        | key            | expires in |
| :----------: | :----: | :------------: | :--------: |
| access token | Header | iksm_session   | 24 hours   |
| gtoken       | Header | X-GameWebToken | 3 hours    |

```json
{
   "isChildRestricted": false,
   "aud": "5vo2i2kmzx6ps1l1vjsjgnjs99ymzcw0",
   "exp": 1755138996,
   "iat": 1755128196,
   "iss": "api-lp1.znc.srv.nintendo.net",
   "jti": "f220837c-1595-4006-856b-c30d9e872362",
   "sub": 4737360831381504,
   "links": {
       "networkServiceAccount": {
           "id": "3f89c3791c43ea57"
       }
   },
   "typ": "id_token",
   "membership": {
       "active": true
   }
}
```

### [Splatoon 3](https://api.lp1.av5ja.srv.nintendo.net/)

|              |        | key         | expires in |
| :----------: | :----: | :---------: | :--------: |
| access token | Body   | bulletToken | 2 hours?   |
| gtoken       | Header | gtoken      | 3 hours    |

```json
{
   "isChildRestricted": false,
   "aud": "5vo2i2kmzx6ps1l1vjsjgnjs99ymzcw0",
   "exp": 1755138996,
   "iat": 1755128196,
   "iss": "api-lp1.znc.srv.nintendo.net",
   "jti": "f220837c-1595-4006-856b-c30d9e872362",
   "sub": 4737360831381504,
   "links": {
       "networkServiceAccount": {
           "id": "3f89c3791c43ea57"
       }
   },
   "typ": "id_token",
   "membership": {
       "active": true
   }
}
```


## Contributors

- [zhxie](https://github.com/zhxie)
- [ultemica](https://github.com/ultemica)

## License

Mudmouth is licensed under [the MIT License](/LICENSE).
