# Code of Conduct

Please read the [Code of Conduct](CODE_OF_CONDUCT.md) document before contributing.

# Tracking Changes

All changes must be merged in via a pull request on GitHub. When issuing a pull request, please add a summary of your changes to the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. A markdown unnumbered list item describing the change(s).
2. Two trailing spaces on the last line describing the change.
3. A list of markdown hyperlinks to the contributors of the change.
    - One entry per line, although usually just one.
4. A list of markdown hyperlinks to the issues that the change addresses.
    - One entry per line, although usually just one.
    - Try to not link to PRs here.
5. All `CHANGELOG.md` content is hard-wrapped at 80 characters.

# Updating the Integration Specs

Jazzy heavily relies on integration tests, but since they're considerably large and noisy, we keep them in a separate repo ([realm/jazzy-integration-specs](https://github.com/realm/jazzy-integration-specs)).

If you're making a PR towards Jazzy that affects the generated docs, please
update the integration specs using the following process:

```shell
git checkout master
git pull
git checkout -
git rebase master
bundle install
bundle exec rake rebuild_integration_fixtures
cd spec/integration_specs/
git checkout -b $jazzy_branch_name
git commit -a -m "update for $jazzy_branch_name"
git push
cd ../../
git commit -a -m "update integration specs"
git push
```

You'll need push access to the integration specs repo to do this. You can
request access from one of the maintainers when filing your PR.

## Making changes to SourceKitten

When changes are landed in the https://github.com/jpsim/SourceKitten repo the
SourceKitten framework located in Jazzy must be updated.

The following may be executed from your `jazzy/` directory.

```
cd SourceKitten/
git checkout master
git pull
cd ..
rake sourcekitten
git add .
git commit -m "..."
```
