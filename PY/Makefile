
# Variables
RUST_SRC=src/cli.rs
RUST_OUT=bin/autux
PYTHON_SRC=src/Lib

# Default target
all: build

# Build Rust CLI
build:
	@echo "Building Rust CLI..."
	cargo build --release --manifest-path $(RUST_SRC)
	mv target/release/cli $(RUST_OUT)

# Install Python package
install:
	@echo "Installing Python package..."
	pip install -e $(PYTHON_SRC)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf target $(RUST_OUT)

# Run tests
test:
	@echo "Running tests..."
	pytest $(PYTHON_SRC)
