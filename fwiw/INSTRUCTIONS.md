# Fairware Integrated Wages (FWIW)

## Purpose:

This directory structure facilitates tracking work efforts, pursuant to the terms of the [Satoshi Fairware License](https://satoshidnc.com/licenses). Read the license preamble for a comprehensive overview.

To facilitate tracking of work efforts on this project, commit messages should include the number of minutes spent on the associated work. The indicated number of minutes may include work performed outside of the git repository. In cases where no material changes in the git repository are otherwise needed, a line should be added to the `META-EFFORTS.md` file describing the effort, and the associated time should be included in the commit message.

## Instructions:

The format for including the time spent must be a parenthetical suffix on the commit message, including the integer number of minutes followed by the letter `m`. For example, a commit that represents 2 hours of work on a new feature might be recorded with a command similar to the following:

```
$ git commit -m "implement XYZ feature (120m)"
```

This facilitates automation of the requirements of the [Satoshi Fairware License](https://satoshidnc.com/licenses).


## Files:

- `INSTRUCTIONS.md` - This file.

- `META-EFFORTS.md` - This file contains a list of work performed outside of the repository. Commits to this file allow time spent on the project to be recorded in cases where no other files are affected.
