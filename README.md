## Pilaf's fork of [mjdominus/anagram-scoring](https://github.com/mjdominus/anagram-scoring)

This fork just adds this README and a tiny change to `Ana.pm` to make the
scripts run for me. I know almost nothing about Perl so it's likely the
original repo was working fine and I just couldn't figure it out.

### Running

To run the scripts on macOS I had to tell Perl to look for packages in `.`,
e.g.:

```bash
$ PERL5LIB="." ./make-scoredict dict-file
```

`dict-file` is any simple word-list file, e.g. the one that comes preinstalled
in macOS/Linux, `/usr/share/dict/words`.

### Scripts overview

The main scripts of interest are:

* `make-scoredict` -- generates a list of scored anagrams
* `simple` -- generates a simple list of unscored anagrams

### References

* [The blog post that got me interested in this](https://blog.plover.com/lang/anagram-scoring.html)
