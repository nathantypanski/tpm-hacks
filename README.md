# tpm2-blobstore

> These are PoC scripts. Don't use them in production.

`tpm-blobstore` uses tpm2-tools on linux to store arbitrary TPM-protected secret
blobs. Kind of like a password manager protected by PCRs. That means the secure
boot state of your system (and other variables of your choice) protect the
decryption capability of your secret blobs.

A neat PoC is to use it as an `SSH_ASKPASS` helper, protecting your SSH
passphrase with the TPM. The downside to storing full SSH keys in the TPM is you
are generally unaware of what the state will be on the next boot after a
kernel/bootloader upgrade; `systemd-cryptsetup` takes care of a lot of
complexity under the hood to make that work. I can always _type_ my
SSH passphrase if I need to. Also, I might want to unlock---say---a
Yubikey-backed secret.

## Usage

Short form: you can write a secret to your TPM with `create-verify-blob` and
read it with `unseal-blob`:

```
$ bin/create-verify-blob readme-secret 2>/dev/null && bin/unseal-blob readme-secret 2>/dev/null
Enter secret:
hello readme
```

Handles to secrets are stored in `${HOME}/.tpm/tpm-blobstore/blobs` by default.

The first time this is run it creates a primary key. This key protects all
subsequent secrets and is bound to TPM PCR registers.

### Sealing a secret

```
$ ./create-verify-blob hello-world
./create-verify-blob hello-world
>>> Building PCR policy (PCRs 0,6,7, sha384)…
e4b4b630af4faa4ce55433f41b0d65ece5c4389b0c84eeb79930a72a716a14e2
Enter secret:

>>> Creating secret ...
name-alg:
  value: sha256
  raw: 0xb
attributes:
  value: fixedtpm|fixedparent
  raw: 0x12
type:
  value: keyedhash
  raw: 0x8
algorithm:
  value: null
  raw: 0x10
keyedhash: 48f05cb8481165fea0490e040495ab65ef2ad6e1bc0c1e4ceb3826e2c512c4f6
authorization policy: e4b4b630af4faa4ce55433f41b0d65ece5c4389b0c84eeb79930a72a716a14e2

>>> Sealed blob written to 2 files:
>>>     '/home/ndt/.tpm/tpm-blobstore/blobs/hello-world_p384.priv'
>>>     '/home/ndt/.tpm/tpm-blobstore/blobs/hello-world_p384.pub'
>>> loading secret blob…
name: 000b977b465139aabe338e0ff094a41d31e028bce9d0dca802d66d23b7cb71d91b85

>>> starting policy session
>>> updating session with current PCR values
e4b4b630af4faa4ce55433f41b0d65ece5c4389b0c84eeb79930a72a716a14e2

>>> Not echoing secret. Set RECOVERED=- to display secret values, or provide a filename.
>>> Success!

PCR Policy:   /home/ndt/.tpm/tpm-blobstore/blobs/hello-world_p384.policy
Public key:   /home/ndt/.tpm/tpm-blobstore/blobs/hello-world_p384.pub
Private key:  /home/ndt/.tpm/tpm-blobstore/blobs/hello-world_p384.priv

[cleanup] rm -rf -- /tmp/tpm.uq2a2tATg
```

Unsealing

```
$ ./unseal-blob hello-world -
>>> Loading sealed object 'hello-world'...
>>> Sealed object loaded successfully. Context: /tmp/tpm.i7JKvtNrj/unseal_loaded_sealed_obj.ctx
>>> Starting policy session for PCR authorization...
>>> Asserting current PCR state (sha384:0,6,7) into policy session...
>>> PCR policy asserted into session.
>>> Attempting to unseal object using policy session...
hello world
>>> Secret unsealed successfully (output was directed to STDOUT).
```

### PCRs

Secrets are, by default, protected by PCR `0,6,7`. You can query the names and
current states of available PCRs with `systemd-analyze`:

```default
# systemd-analyze pcrs
NR NAME                SHA256
 0 platform-code       [                            sha256                            ]
 1 platform-config     [                            sha256                            ]
 2 external-code       [                            sha256                            ]
 3 external-config     [                   (same as external-code)                    ]
 4 boot-loader-code    [                            sha256                            ]
 5 boot-loader-config  [                            sha256                            ]
 6 host-platform       [                            sha256                            ]
 7 secure-boot-policy  [                            sha256                            ]
 8 -                   0000000000000000000000000000000000000000000000000000000000000000
 9 kernel-initrd       [                            sha256                            ]
10 ima                 0000000000000000000000000000000000000000000000000000000000000000
11 kernel-boot         [                            sha256                            ]
12 kernel-config       0000000000000000000000000000000000000000000000000000000000000000
13 sysexts             0000000000000000000000000000000000000000000000000000000000000000
14 shim-policy         0000000000000000000000000000000000000000000000000000000000000000
15 system-identity     [                            sha256                            ]
16 debug               0000000000000000000000000000000000000000000000000000000000000000
17 -                   ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
18 -                   ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
19 -                   ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
20 -                   ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
21 -                   ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
22 -                   ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
23 application-support 0000000000000000000000000000000000000000000000000000000000000000
```

## `SSH_ASKPASS`

There's an askpass helper called [`tpm-ssh-askpass`](bin/tpm-ssh-askpass) that
can function as an askpass helper for SSH keys.

First write your ssh passphrase to a blob named `ssh-passphrase`:

```
$ create-verify-blob ssh-passphrase 2>/dev/null
Enter secret:
```

Clear your agent:

```
github.com/nathantypanski/tpm2-blobstore $ ssh-add -D
All identities removed.
```

Now, setting `SSH_ASKPASS`:

```
$ SSH_ASKPASS="$(readlink -f bin/tpm-ssh-askpass)" ssh-add ~/.ssh/id_ed25519  < /dev/null
Identity added: /home/ndt/.ssh/id_ed25519
```

## Running tests

Use `test/create-unseal-test`.
