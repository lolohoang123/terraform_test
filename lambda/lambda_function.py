def handler(event, context):
    first = event.get("a", 0)
    b = event.get("b", 0)
    return {"sum": first + b}
