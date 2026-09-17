from ollama import chat

def ollama_ask(prompt: str, model: str = "qwen2.5-coder:7b"):

    response = chat(
        model = model,
        messages = [
            {
                "role": "user", "content": prompt
            }
        ]
    )

    # Get the response
    return response.message.content

def ollama_read(file:str, prompt: str, model: str = "qwen2.5-coder:7b"):

    with open(file, "r", encoding="utf-8") as file:
        contents = file.read()

    response = chat(
        model = model,
        messages = [
            {
                "role": "user", "content": f"Look at this file: {contents}. After reading the data, respond based on this prompt: {prompt}"
            }
        ]
    )

    # Get the response
    return response.message.content
