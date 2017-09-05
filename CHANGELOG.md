# [0.10.1] - 2017-09-05 Alfonso Mancilla (#23)
## Changed
- Inheritance: Allow subsclasses to overwrite methods.

# [0.10.0] - 2017-09-05 Alfonso Mancilla (#22)
## Added
- References ($ref):
  Support for more JSON pointers formats:
    1. #/key1/key2/.../keyN
    2. path-to-file.json
    3. path-to-file.json#/key1/key2/.../keyN

# [0.9.1] - 2017-09-04 Alfonso Mancilla (#20)
- Support primitive type: integer.

# 0.9.0
- Allow enums

# 0.8.0
- Make error messages look better with json pretty print

# 0.7.0
- Add object equality comparison

# 0.6.0
- Add marshalling support

# 0.5.0
- Make `Blumquist#to_s` do an `inspect`

# 0.4.4
- No changes, 0.4.3 seems stuck in limbo w/ rubygems/cloudfront

# 0.4.3
- Allow arrays with single-array-types

# 0.4.2
- Allow objects with single-array-types

# 0.4.1
- Fix broken arrays of objects

# 0.4.0
- Support properties with multiple types
  (e.g. an object, but also null)

# 0.3.2
- Fix #2 (arrays of primitives)

# 0.3.1
- Support array type definitions that are expressed as an object
  or as an array of objects

# 0.3.0
- Important whitespace changes
- Proper exceptions
- Disallow arrays with undefined item types

# 0.2.0 (Oct-30-15)
- Validate objects (if desired)
- Use keyword arguments (in <2.0 compat mode)
