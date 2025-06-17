import os
import numpy as np
import onnx
from onnx import helper, TensorProto, numpy_helper

def create_complex_onnx_model(output_path):
    # Define input and output tensors
    X = helper.make_tensor_value_info('X', TensorProto.FLOAT, [1, 1, 28, 28])
    Y = helper.make_tensor_value_info('Y', TensorProto.FLOAT, [1, 10])
    
    # Create weight and bias tensors
    w1 = numpy_helper.from_array(
        np.random.randn(16, 1, 3, 3).astype(np.float32),
        name='conv1.weight'
    )
    b1 = numpy_helper.from_array(
        np.random.randn(16).astype(np.float32),
        name='conv1.bias'
    )
    w2 = numpy_helper.from_array(
        np.random.randn(32, 16, 3, 3).astype(np.float32),
        name='conv2.weight'
    )
    b2 = numpy_helper.from_array(
        np.random.randn(32).astype(np.float32),
        name='conv2.bias'
    )
    w3 = numpy_helper.from_array(
        np.random.randn(10, 32 * 5 * 5).astype(np.float32),
        name='fc1.weight'
    )
    b3 = numpy_helper.from_array(
        np.random.randn(10).astype(np.float32),
        name='fc1.bias'
    )
    
    # Create nodes for the model
    conv1_node = helper.make_node(
        'Conv',
        inputs=['X', 'conv1.weight', 'conv1.bias'],
        outputs=['conv1_out'],
        name='conv1',
        kernel_shape=[3, 3],
        pads=[1, 1, 1, 1]
    )
    
    relu1_node = helper.make_node(
        'Relu',
        inputs=['conv1_out'],
        outputs=['relu1_out'],
        name='relu1'
    )
    
    pool1_node = helper.make_node(
        'MaxPool',
        inputs=['relu1_out'],
        outputs=['pool1_out'],
        name='pool1',
        kernel_shape=[2, 2],
        strides=[2, 2]
    )
    
    conv2_node = helper.make_node(
        'Conv',
        inputs=['pool1_out', 'conv2.weight', 'conv2.bias'],
        outputs=['conv2_out'],
        name='conv2',
        kernel_shape=[3, 3],
        pads=[1, 1, 1, 1]
    )
    
    relu2_node = helper.make_node(
        'Relu',
        inputs=['conv2_out'],
        outputs=['relu2_out'],
        name='relu2'
    )
    
    pool2_node = helper.make_node(
        'MaxPool',
        inputs=['relu2_out'],
        outputs=['pool2_out'],
        name='pool2',
        kernel_shape=[2, 2],
        strides=[2, 2]
    )
    
    flatten_node = helper.make_node(
        'Flatten',
        inputs=['pool2_out'],
        outputs=['flatten_out'],
        name='flatten'
    )
    
    gemm_node = helper.make_node(
        'Gemm',
        inputs=['flatten_out', 'fc1.weight', 'fc1.bias'],
        outputs=['gemm_out'],
        name='fc1'
    )
    
    softmax_node = helper.make_node(
        'Softmax',
        inputs=['gemm_out'],
        outputs=['Y'],
        name='softmax',
        axis=1
    )
    
    # Create the graph
    graph_def = helper.make_graph(
        [conv1_node, relu1_node, pool1_node, 
         conv2_node, relu2_node, pool2_node, 
         flatten_node, gemm_node, softmax_node],
        'complex-cnn-model',
        [X],
        [Y],
        initializer=[w1, b1, w2, b2, w3, b3]
    )
    
    # Create the model with IR version 10 for compatibility
    model_def = helper.make_model(
        graph_def,
        producer_name='onnx-example',
        opset_imports=[helper.make_opsetid("", 13)],
        ir_version=10  # Set IR version to 10 for compatibility with ONNX Runtime
    )
    
    # Validate the model
    onnx.checker.check_model(model_def)
    
    # Save the model
    onnx.save(model_def, output_path)
    print(f"Model saved to {output_path}")
    print(f"Model size: {os.path.getsize(output_path) / 1024:.2f} KB")

if __name__ == "__main__":
    output_path = "models/complex-cnn-model.onnx"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    create_complex_onnx_model(output_path)
