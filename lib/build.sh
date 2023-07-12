#!/bin/bash
flutter build web 2>&1 | grep -v "^#" | grep -v "^<"
