# Please release me, let me go,

[*For I don't love you any more...*](https://youtu.be/6S9ecXWCBCc?t=11s)

[![Package status](https://img.shields.io/npm/v/please-release-me.svg?style=flat-square)](https://www.npmjs.com/package/please-release-me)
[![License](https://img.shields.io/github/license/philbooth/please-release-me.svg?style=flat-square)](https://opensource.org/licenses/MIT)

* [What is it?](#what-is-it)
* [What does it do?](#what-does-it-do)
* [What doesn't it do?](#what-doesnt-it-do)
* [How do I install it?](#how-do-i-install-it)
* [How do I use it?](#how-do-i-use-it)
* [What license is it released under?](#what-license-is-it-released-under)

## What is it?

An automated release script
for npm,
built to work with
the conventions
used by my packages.
If you're not me,
there's a good chance
it won't work for you.

## What does it do?

Performs sanity checks,
bumps the version number
updates the change log,
and creates a new git tag.

Specifically,
it runs through each of the following steps
in order:

1. If it looks like there is a `lint` command
   in `package.json`,
   execute the command `npm run lint`.
   If the `lint` command fails,
   the release is aborted.

2. If it looks like there is a `test` command
   in `package.json`,
   execute the command `npm t`.
   If the `test` command fails,
   the release is aborted.

2. If it looks like there is a `minify` command
   in `package.json`,
   execute the command `npm run minify`.
   If the `minify` command fails,
   the release is aborted.

4. Generate a list of commits
   since the last tag.

5. Based on the commits from `4`,
   bump the version string like so:

   * If any commit message
     begins with `break:` or `breaking:`,
	 increment the major version.

   * Otherwise,
     if any commit message
     begins with `feat:` or `feature:`,
	 increment the minor version.

   * Otherwise,
	 increment the patch number.

6. Write the freshly bumped version string
   to `package.json`.

7. If `bower.json` exists,
   write the freshly bumped version string
   to `bower.json`.

8. If `component.json` exists,
   write the freshly bumped version string
   to `component.json`.

9. If a change log is detected,
   write a summary of the changes
   to the change log.
   It will recognise any of the following file names:

   * `CHANGELOG.md`

   * `CHANGELOG.txt`

   * `CHANGELOG`

   * `CHANGES.md`

   * `CHANGES.txt`

   * `CHANGES`

   * `HISTORY.md`

   * `HISTORY.txt`

   * `HISTORY`

10. Commit all changes
    made by the preceding steps.

11. Tag the release
    with the freshly bumped version string.

## What doesn't it do?

* `git push`

## How do I install it?

```
npm i -g please-release-me
```

## How do I use it?

Just run the command `release`,
with no arguments:

```
release
```

## What license is it released under?

[MIT](LICENSE).

