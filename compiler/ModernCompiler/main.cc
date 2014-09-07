#include "llvm/Analysis/Passes.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/PassManager.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/ExecutionEngine/JIT.h"

#include <string>
#include <iostream>

#include "ASTGenerator.h"
#include "Node.h"

int main(int argc, char *argv[]) 
{
	ASTGenerator generator(argv[1]);
	generator.Initialize();
	
	Node *node = generator.Generate();
	std::cout << node->ToString() << "\n";

	llvm::InitializeNativeTarget();

	llvm::Module module("test", llvm::getGlobalContext());
	llvm::IRBuilder<> builder(llvm::getGlobalContext());

	node->Codegen(module, builder, NULL);
	
	// create JIT

	std::string ErrStr;
	llvm::ExecutionEngine *executionEngine =
		llvm::EngineBuilder(&module).setErrorStr(&ErrStr).create();
	if (!executionEngine) {
		fprintf(stderr, "Could not create ExecutionEngine: %s\n", ErrStr.c_str());
		getchar();
	}

	// add optimizations

	llvm::FunctionPassManager fpm(&module);

	// Set up the optimizer pipeline.  Start with registering info about how the
	// target lays out data structures.
	module.setDataLayout(executionEngine->getDataLayout());
	fpm.add(new llvm::DataLayoutPass(&module));
	// Provide basic AliasAnalysis support for GVN.
	fpm.add(llvm::createBasicAliasAnalysisPass());
	// Do simple "peephole" optimizations and bit-twiddling optzns.
	fpm.add(llvm::createInstructionCombiningPass());
	// Reassociate expressions.
	fpm.add(llvm::createReassociatePass());
	// Eliminate Common SubExpressions.
	fpm.add(llvm::createGVNPass());
	// Simplify the control flow graph (deleting unreachable blocks, etc).
	fpm.add(llvm::createCFGSimplificationPass());

	fpm.doInitialization();

	void *mainFunctionPtr = executionEngine->getPointerToFunction(module.getFunction("main"));
	int(*FP)() = (int(*)())(intptr_t)mainFunctionPtr;

	llvm::outs() << module;

	fprintf(stderr, "\nPROGRAM EVALUATED TO: %d\n", FP());

	getchar();

}