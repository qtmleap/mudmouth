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

### [Zelda Notes](https://api.lp1.87abc152.srv.nintendo.net/)

|              |        | key      | expires in |
| :----------: | :----: | :------: | :--------: |
| access token | Header | a5_token | encrypted  |
| gtoken       | Header | gtoken   | 3 hours    |

```json
{
   "isChildRestricted": false,
   "aud": "5315326957223936",
   "exp": 1755146431,
   "iat": 1755135631,
   "iss": "api-lp1.znc.srv.nintendo.net",
   "jti": "2fbbdb23-e59a-4a4b-82d5-efc64a960018",
   "sub": "4737360831381504",
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

The response body is encrypted by AES.

```json
{
    "ciphertext":"d7eeb5690ea5e063605a8f7ecee9545d99b8bdadd8d8cf3fba109938abc4c8fa8e477c1b6d0fdda345a52b3916c61c03a9c1f4ba43b743502efd06bae6489fc403ce8434c9989a000f0868d00fe6001c09ccc9e6b986951caddb54c451f5fb04d955b28f31997ba8afe746125af488",
    "iv":"304b70f6d65e07dc2044a05d",
    "tag":""
}
```

## Contributors

- [zhxie](https://github.com/zhxie)
- [ultemica](https://github.com/ultemica)

## License

Mudmouth is licensed under [the MIT License](/LICENSE).
