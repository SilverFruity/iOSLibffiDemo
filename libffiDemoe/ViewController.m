//
//  ViewController.m
//  libffiDemoe
//
//  Created by Jiang on 2020/7/18.
//  Copyright © 2020 SilverFruity. All rights reserved.
//

#import "ViewController.h"
#import "ffi.h"
@interface ViewController ()

@end

@implementation ViewController
double addFunc(int a, double b){
    return a + b;
}
void libffi_add(){
    ffi_cif cif;
    //参数值
    int a = 100;
    double b = 0.5;
    void *args[2] = { &a , &b};
    //参数类型数组
    ffi_type *argTyeps[2] = { &ffi_type_sint, &ffi_type_double };
    ffi_type *rettype = &ffi_type_double;

    //根据参数和返回值类型，设置cfi
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, sizeof(args) / sizeof(void *), rettype, argTyeps);

    // 返回值
    double result = 0;
    
    //使用cif函数签名信息，调用函数
    ffi_call(&cif, (void *)&addFunc, &result, args);
    
    // assert
    assert(result == 100.5);
}
void libffi_nslog(){
    ffi_cif cif;
    //参数值
    NSString *format = @"%@";
    NSString *value = @"123";
    void *args[2] = { &format , &value};
    //参数类型数组
    ffi_type *argTyeps[2] = { &ffi_type_pointer, &ffi_type_pointer };
    ffi_type *rettype = &ffi_type_void;

    //根据参数和返回值类型，设置cfi
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, sizeof(argTyeps) / sizeof(void *), rettype, argTyeps);
    
#ifdef __arm64__
    // 限制函数在寄存器上的参数个数为1
    // void NSLog(NSString *format, ...) 第一个参数为指针，其他参数全在栈上
    cif.aarch64_nfixedargs = 1;
#endif
    
    //使用cif函数签名信息，调用函数。
    //这里能传NULL的原因是，当返回值为void的时候，不会使用返回值指针，后续的具体实现会讲到。
    ffi_call(&cif, (void *)&NSLog, NULL, args);
}

void register_add_func(ffi_cif *cif,void *ret,void **args,void *userdata){
    assert([(__bridge NSString *)userdata isEqualToString:@"123"]);
    //其实这里可通过cif中参数类型和返回值类型，动态获取参数。
    //此处代码，仅仅根据 libffi_register_add 中的 double(*add)(int, double) 进行运算
    int a = *(int *)args[0];
    double b = *(double *)args[1];
    *(double *)ret = a + b;
}

void libffi_register_add(){
    
    double (*add)(int, double) = NULL;
    
    //根据参数和返回值类型，设置cfi
    ffi_type *argTyeps[2] = { &ffi_type_sint, &ffi_type_double };
    ffi_type *rettype = &ffi_type_double;
    ffi_cif *cif = malloc(sizeof(ffi_cif));
    ffi_prep_cif(cif, FFI_DEFAULT_ABI, sizeof(argTyeps) / sizeof(void *), rettype, argTyeps);
    
    //使用cif和外部指针，生成ffi_closure
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void *)&add);
    
    //自定义信息
    NSString *userdata =  @"123";
    
    //实际使用时, ffi_closure和userdata都需要一直存在
    CFRetain((__bridge CFTypeRef)(userdata));
    
    //将add替换为闭包
    /* 执行顺序:
      1. ffi_closure_SYSV_V或者ffi_closure_SYSV
      2. ffi_closure_SYSV_inner
      3. register_add_func
     */
    ffi_prep_closure_loc(closure, cif, &register_add_func, (__bridge void *)(userdata), add);

    double result = add(1, 0.5);
    
    assert(result == 1.5);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    libffi_add();
    libffi_nslog();
    libffi_register_add();

}


@end
