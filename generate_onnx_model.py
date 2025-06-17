import os
import numpy as np
import onnx
from onnx import helper, TensorProto

def create_simple_onnx_model(output_path):
    # Define input and output tensors
    X = helper.make_tensor_value_info('X', TensorProto.FLOAT, [1, 1, 28, 28])
    Y = helper.make_tensor_value_info('Y', TensorProto.FLOAT, [1, 10])
    
    # Create a simple graph with a single Softmax node
    node_def = helper.make_node(
        'Softmax',
        inputs=['X'],
        outputs=['Y'],
        name='softmax_node',
        axis=1
    )
    
    # Create the graph
    graph_def = helper.make_graph(
        [node_def],
        'simple-model',
        [X],
        [Y]
    )
    
    # Create the model
    model_def = helper.make_model(
        graph_def,
        producer_name='onnx-example',
        opset_imports=[helper.make_opsetid("", 13)]
    )
    
    # Validate the model
    onnx.checker.check_model(model_def)
    
    # Save the model
    onnx.save(model_def, output_path)
    print(f"Model saved to {output_path}")
    print(f"Model size: {os.path.getsize(output_path) / 1024:.2f} KB")

if __name__ == "__main__":
    output_path = "models/valid-simple-model.onnx"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    create_simple_onnx_model(output_path)
