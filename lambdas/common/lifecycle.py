"""Project lifecycle rules.

Allowed status transitions:

    draft  -> active, archived
    active -> draft, archived
    archived -> (terminal)
"""

from responses import conflict

ALLOWED_TRANSITIONS = {
    ("draft", "active"),
    ("draft", "archived"),
    ("active", "draft"),
    ("active", "archived"),
}

VALID_STATUSES = ("draft", "active", "archived")


def assert_transition(current, target):
    if current == target:
        return
    if (current, target) not in ALLOWED_TRANSITIONS:
        raise conflict(f"Illegal project lifecycle transition: {current} -> {target}")
