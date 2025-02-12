#!/bin/bash

set -euo pipefail

# armour/ARMOUR/Armour -> armor/ARMOR/Armor
grep -rli --include="*.dm" 'armour' . | xargs -i@ sed -i -e 's/armour/armor/g;s/ARMOUR/ARMOR/g;s/Armour/Armor/g' @

# colour/COLOUR/Colour -> color/COLOR/Color
grep -rli --include="*.dm" 'colour' . | xargs -i@ sed -i -e 's/colour/color/g;s/COLOUR/COLOR/g;s/Colour/Color/g' @
