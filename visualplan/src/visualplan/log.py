# Copyright 2013-2023 The Wazo Authors  (see the AUTHORS file)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

import re


class LogParser:
    _EXECUTE_REGEX = re.compile(r'Executing \[([^@]+)@([a-zA-Z0-9_\-]+):(\d+)\]')

    def parse(self, fobj):
        result = _LogParseResult()
        for log_line in fobj:
            mo = self._EXECUTE_REGEX.search(log_line)
            if mo:
                extension = mo.group(1)
                context = mo.group(2)
                priority = int(mo.group(3))
                result._add(context, extension, priority)
        return result

    def parse_file(self, filename):
        with open(filename) as fobj:
            return self.parse(fobj)


class _LogParseResult:
    def __init__(self):
        self._contexts = {}

    def _add(self, context, extension, priority):
        self._contexts.setdefault(context, {}).setdefault(extension, set()).add(priority)

    def is_executed(self, context, extension, priority):
        extensions = self._contexts.get(context)
        if extensions:
            priorities = extensions.get(extension)
            if priorities:
                return priority in priorities
        return False

    def list_executed_extensions(self, context, priority):
        return [
            extension for extension, priorities
            in self._contexts.get(context, {}).items()
            if priority in priorities
        ]
