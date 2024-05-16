# Fairware Integrated Wages (FWIW)

## Purpose:

This directory structure facilitates tracking work efforts, pursuant to the terms of the [Satoshi Fairware License](https://satoshidnc.com/licenses). Read the license preamble for a comprehensive overview.

To facilitate tracking of work efforts on this project, commit messages should include the number of minutes spent on the associated work. The indicated number of minutes may include work performed outside of the git repository. In cases where no material changes in the git repository are otherwise needed, a line should be added to the `META-EFFORTS.md` file describing the effort, and the associated time should be included in the commit message.

## Instructions:

The exact format for including the time spent is described in the file `timecalc.sh`. Time spent can be manually indicated with the first word in the commit subject line, using one of the following two formats:

- `1.5h` would signify one and a half hours spent on this (and any overlapping prior) commits.
- `90m` would also signify one and a half hours.

For example, a commit that represents 2 hours of work on a new feature might be recorded with a command similar to the following:

```
$ git commit -m "2h implement XYZ feature"
```

This facilitates automation of the requirements of the [Satoshi Fairware License](https://satoshidnc.com/licenses).


## Files:

- `INSTRUCTIONS.md` - This file.

- `META-EFFORTS.md` - Contains a list of work performed outside of the repository. Commits to this file are for time spent on the project to be recorded in cases where no other files are affected.

- `timecalc.sh` - Calculates the total time each dev contributed to the current git repo, and the total wages asked.
