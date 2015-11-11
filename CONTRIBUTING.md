## Tracking changes

When issuing a pull request, please add a summary of your changes to `CHANGELOG.md`.

# Making changes to SourceKitten

When changes are landed in the https://github.com/jpsim/SourceKitten repo the
SourceKitten framework located in jazzy must be updated.

The following may be executed from your `jazzy/` directory.

```
cd SourceKitten
git checkout master
git pull
cd ..
rake sourcekitten
git add .
git commit -m "..."
```
