def hex_to_coe(hex_file, coe_file):
    with open(hex_file, 'r') as f:
        lines = f.readlines()

    hex_data = []
    for line in lines:
        if line.startswith('@') or not line.strip():
            continue
        hex_data.extend(line.split())

    with open(coe_file, 'w') as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        f.write(",\n".join(hex_data) + ";")

hex_to_coe('main.hex', 'main.coe')