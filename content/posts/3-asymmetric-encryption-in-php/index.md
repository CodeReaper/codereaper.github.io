---
title: Asymmetric encryption in PHP
date: 2014-06-03T00:00:00+02:00
draft: false
---

One of the use cases of asymmetric encryption is to allow others to send you encrypted data that only you can read. No one says the receiver and sender are both running [PHP](http://www.php.net/), in fact there will be multiple language examples available.

This type of encryption is also refered to as public key cryptography, because it requires you to use a private key and a public key.

Let us start with creating those, like so:

```sh
# create the private key private.key
openssl genrsa -out private.key 2048
# create the public key public.pem
openssl rsa -in private.key -outform PEM -pubout -out public.pem
```

## Mind the pitfalls
You might be tempted to use the [openssl_​public_​encrypt](http://www.php.net/openssl_public_encrypt) and [openssl_​private_​decrypt](http://www.php.net/openssl_private_decrypt) methods, but be warned they are not really useful. They only support very small data sizes, for instance on my mac the maximum size of input is 245 bytes.

The encryption and decryption methods you will want to use is [openssl_​seal](http://www.php.net/openssl_seal) and [openssl_​open](http://www.php.net/openssl_open), but they do require a little extra of you as a developer. You need to manage not just the encrypted bytes, but also some extra bytes that match the public key used to encrypt the data. This is because the sealing method allows you to encrypt the same data for multiple recipients.

## There and back again
Below is an example of how to generate sealed data and an envelope and use them to recreate the original data:

```php
<?php

$private_key = openssl_get_privatekey(file_get_contents('private.key'));
$public_key = openssl_get_publickey(file_get_contents('public.pem'));

$data = '{"data":"makes life worth living"}';

echo "data in:\n$data\n\n";

$encrypted = $e = NULL;
openssl_seal($data, $encrypted, $e, array($public_key));

$sealed_data = base64_encode($encrypted);
$envelope = base64_encode($e[0]);

echo "sealed data:\n$sealed_data\n\n";
echo "envelope:\n$envelope\n\n";

$input = base64_decode($sealed_data);
$einput = base64_decode($envelope);

$plaintext = NULL;
openssl_open($input, $plaintext, $einput, $private_key);

echo "data out:\n$plaintext\n";
```

Below is some example output, but note that the output will be different each time you generate sealed data and an envelope.

```sh
data in:
{"data":"makes life worth living"}

sealed data:
ZDrH0um1qRyFiQMOivlS6taxLrR+KyXH3cDAcqgcxWOPCw==

envelope:
x9qSCAoyx6ueTFH5cyosPpUhye0hlBvWxF7DxniLNBv/EpIsebXqHhCh4zhTqnaNFS+48PewNZbGUwnkMCLr8MrpMr5mNxtrovcGmhHL5pwBovyUorHcGeiQHN3QXn9n4vDVPGZuEnPw3SZxqw8HqItYyjuXsrxtCdN4nHlwwRJ9s37kXYr+Y8UQ7gzMRbYoO4E188RnWt7HhvKg08emRJHCRzW5YJDOx1gxd0+qE1EMjXGpfw0WB9lacl09Sg4tdsrMDIvKu2Fi21c7HD9Er21dmGUaq465a0zRYqLaDz476RYlTim40BdjDPPHb1TJGBM4BD+ElkI8YbXJ7AjfAQ==

data out:
{"data":"makes life worth living"}
```

For examples in other languages check out the [unsealed-secrets at github](https://github.com/CodeReaper/unsealed-secrets).

Enjoy your new knowledge and your data being safer.
