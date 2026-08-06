from function_app import increment_count


def test_increment_count():
    entity = {"count": 5}
    result = increment_count(entity)
    assert result["count"] == 6


def test_increment_count_from_zero():
    entity = {"count": 0}
    result = increment_count(entity)
    assert result["count"] == 1