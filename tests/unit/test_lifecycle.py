import pytest

from conftest import load_module

lifecycle = load_module("common", "lifecycle.py")
responses = load_module("common", "responses.py")


@pytest.mark.parametrize(
    "current,target",
    [
        ("draft", "active"),
        ("draft", "archived"),
        ("active", "draft"),
        ("active", "archived"),
    ],
)
def test_allowed_transitions_pass(current, target):
    lifecycle.assert_transition(current, target)


def test_same_status_is_a_no_op():
    lifecycle.assert_transition("draft", "draft")


@pytest.mark.parametrize(
    "current,target",
    [
        ("archived", "active"),
        ("archived", "draft"),
    ],
)
def test_terminal_archived_rejects_reopening(current, target):
    with pytest.raises(responses.ApiError) as excinfo:
        lifecycle.assert_transition(current, target)
    assert excinfo.value.status == 409
    assert "Illegal project lifecycle transition" in excinfo.value.message
