#!/usr/bin/env python3

def hello_from_python():
    print("Hello from Python in FlutterPy!")
    return {"message": "Hello from Python!", "status": "success", "value": 42}

def add_numbers(a, b):
    return a + b

if __name__ == "__main__":
    result = hello_from_python()
    print(f"Result: {result}")
    print(f"1 + 2 = {add_numbers(1, 2)}") 