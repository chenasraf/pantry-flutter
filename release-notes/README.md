# Release notes

The notes each store shows for a release are written by hand, here.

- `next/<slug>.md`: one fragment per change people will notice, committed together with its `feat`
  or `fix` commit.
- `<version>/`: the notes for a released version, one file per destination in `config.yml` plus
  `full.md`, which holds every fragment of the release.
- `config.yml`: the destinations, their character limits, and which platforms reach which store.

A fragment:

```md
---
kind: fix # feat | fix
area: shopping # changes in the same area are grouped together
platforms: [all] # or android / wear / mobile / ios / apple / macos / desktop
weight: notable # headline | notable | minor
onboarding: no # yes | no | maybe
onboarding_reason: # required when onboarding is yes
---

Totals on a shopping trip now count every item's quantity, so the estimate matches what you pay at
the till.
```

Once the release PR is open, the fragments in `next/` are written up into `<version>/` and removed
from `next/`. The release PR can't merge until that folder is complete, and a release pushed without it is not
tagged.
