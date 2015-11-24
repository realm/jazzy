## Tracking changes

All changes should be made via pull requests on GitHub.

When issuing a pull request, please add a summary of your changes to
the `CHANGELOG.md` file.

We follow the same syntax as CocoaPods' CHANGELOG.md:

1. One Markdown unnumbered list item desribing the change.
2. 2 trailing spaces on the last line describing the change.
3. A list of Markdown hyperlinks to the contributors to the change. One entry
   per line. Usually just one.
4. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one.
5. All CHANGELOG.md content is hard-wrapped at 80 characters.

## Updating the integration specs

Jazzy heavily relies on integration tests, but since they're considerably large
and noisy, we keep them in a separate repo
([realm/jazzy-integration-specs](https://github.com/realm/jazzy-integration-specs)).

If you're making a PR towards jazzy that affects the generated docs, please
update the integration specs using the following process:

```shell
git checkout master
git pull
git checkout -
git rebase master
bundle install
bundle exec rake rebuild_integration_fixtures
cd spec/integration_specs
git checkout -b $jazzy_branch_name
git commit -a -m "update for $jazzy_branch_name"
git push
cd ../../
git commit -a -m "update integration specs"
git push
```

## Making changes to SourceKitten

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
