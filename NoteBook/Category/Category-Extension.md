# Category Extension

## Category简介

Category：分类、类别。

```Objective-C
@interface Model (Temp)
@end
@implementation Model (Temp)
- (void)test{
}
@end
```

- 为已经存在的类添加方法、协议、属性。
- 把类的实现部分分开在不同的文件里面（不同的功能组织在不同的category里面）。
- 声明私有方法。
- 把framework的私有方法公开

## Extension简介

Extension 扩展、延展、匿名分类。

```Objective-C
@interface ViewController ()
//这部分就是extension
@end
@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
}
@end
```

- Extension看起来很像一个匿名的category。
- Extension存在于一个.h文件中，或者Extension寄生于一个类的.m文件中。
- Extension一般用来隐藏类的私有信息。

## Category和Extension的区别

**<code style="color: #e96900">类实例</code>：指一块内存区域，包含了isa指针和所有的成员变量**

```Objective-C
typedef struct objc_class *Class;
```

objc_class结构体

```Objective-C
struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;

#if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
#endif

} OBJC2_UNAVAILABLE;
```

#### <code style="color: #e96900">Extension：</code>

- 编译期决议，是类的一部分，在编译期和头文件里的@interface以及实现文件里的@implement一起形成一个完整的类，与类一同产生或消失。声明的实例变量是存放在objc_class的ivars里面的。
- 不但可以声明方法、属性，还可以声明实例变量，一般是私有的。

#### <code style="color: #e96900">Category：</code>

- 方法和属性并不“属于”类实例，而成员变量“属于”类实例。
- 分类没有自己的isa指针，而类有自己的isa指针
- 运行期决议的，无法添加实例变量。【因为在运行期，对象的内存布局已经确定【ivars已经确定】，如果添加实例变量就会破坏类的内部布局，这对编译型语言来说是灾难性的】。但方法定义是在objc_class中管理的，不管如何增删类方法，都不影响类实例的内存布局【ivars就代表着内存布局】，已经创建出的类实例仍然可正常使用
- 可以扩充@property属性，但不会自动生成实例变量、setter、getter方法，需要使用Runtime关联属性，否则调用属性会crash。
- 捕获某个类的所有属性时，是从objc_class 的结构体指针的ivars获取所有属性，因此拿不到该类的Category中的属性

## Category结构

[runtime源码地址](https://opensource.apple.com/tarballs/objc4/)

在runtime.h中的定义

```Objective-C
typedef struct objc_category *Category;
```

objc_category结构体

```Objective-C
struct objc_category {
    char * _Nonnull category_name                            OBJC2_UNAVAILABLE;
    char * _Nonnull class_name                               OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable instance_methods     OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable class_methods        OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
}  
```

在objc-runtime-new.h文件中，category结构看出：可以添加 实例方法，类方法，协议。

```C
struct category_t {
    const char *name; // 👈name 是指 class_name 而不是 category_name
    classref_t cls; // 👈cls是要扩展的类对象，编译期间是不会定义的，而是在Runtime阶段通过name对应到对应的类对象
    struct method_list_t *instanceMethods;
    struct method_list_t *classMethods;
    struct protocol_list_t *protocols;
    struct property_list_t *instanceProperties; // 👈Category里所有的properties
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;

    method_list_t *methodsForMeta(bool isMeta) {
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);

    protocol_list_t *protocolsForMeta(bool isMeta) {
        if (isMeta) return nullptr;
        else return protocols;
    }
};
```

## 编译器处理Category

```Objective-C
//👇.h文件
@interface CategotyModel : NSObject
@end
@interface CategotyModel (ZH)
@property(nonatomic, copy) NSString *zh_name;
- (void)zh_testLog;
@end
//👇.m文件
@implementation CategotyModel
@end
@implementation CategotyModel (ZH)
- (void)zh_testLog{
    NSLog(@"zhtestlogzh");
}
@end
```

对以上代码编译处理

```bash
//编译依赖UIKit的文件
xcrun -sdk iphonesimulator clang -rewrite-objc ViewController.m
//编译NSObject文件
clang -rewrite-objc CategotyModel.m
```

得到以下代码

### 编译器根据方法构造静态函数

```C
/**👇可以看出变量的命名方式：_I_ + 类名 + _分类名_ + 方法名。*/

// @interface CategotyModel (__ZH)
/* @end */
// @implementation CategotyModel (ZH)
static void _I_CategotyModel_ZH_zh_testLog(CategotyModel * self, SEL _cmd) {
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_d__twpwm6h51lv49p8td2076ghc0000gn_T_CategotyModel_8f2285_mi_0);
}
// @end
```

### 定义一系列结构体

```C
struct _prop_t {
    const char *name;
    const char *attributes;
};

struct _protocol_t;

struct _objc_method {
    struct objc_selector * _cmd;
    const char *method_type;
    void  *_imp;
};

struct _protocol_t {
    void * isa;  // NULL
    const char *protocol_name;
    const struct _protocol_list_t * protocol_list; // super protocols
    const struct method_list_t *instance_methods;
    const struct method_list_t *class_methods;
    const struct method_list_t *optionalInstanceMethods;
    const struct method_list_t *optionalClassMethods;
    const struct _prop_list_t * properties;
    const unsigned int size;  // sizeof(struct _protocol_t)
    const unsigned int flags;  // = 0
    const char ** extendedMethodTypes;
};

struct _ivar_t {
    unsigned long int *offset;  // pointer to ivar offset location
    const char *name;
    const char *type;
    unsigned int alignment;
    unsigned int  size;
};

struct _category_t {
    const char *name;
    struct _class_t *cls;
    const struct _method_list_t *instance_methods;
    const struct _method_list_t *class_methods;
    const struct _protocol_list_t *protocols;
    const struct _prop_list_t *properties;
};
```

### 编译器生成了实例方法列表

```C
/**👇编译器生成了实例方法列表：_OBJC_$_CATEGORY_INSTANCE_METHODS_CategotyModel_$_ZH

【可以看出变量的命名方式：_OBJC_$_ + 方法列表 + _CategotyModel_ + $_ZH。因此category扩展命名不能重复，否则编译器报错】
*/
static struct /*_method_list_t*/ {
    unsigned int entsize;  // sizeof(struct _objc_method)
    unsigned int method_count;
    struct _objc_method method_list[1];
} _OBJC_$_CATEGORY_INSTANCE_METHODS_CategotyModel_$_ZH __attribute__ ((used, section ("__DATA,__objc_const"))) = {
    sizeof(_objc_method),
    1, // 👈方法个数

    // 👇根据方法构造objc_selector结构体，若有多个方法依次向后加参数。
    /**  v16@0:8
    v/@：返回值void/Object对象
    */
    {{(struct objc_selector *)"zh_testLog", "v16@0:8", (void *)_I_CategotyModel_ZH_zh_testLog}}

};
```

### 编译器生成了属性方法列表

```C

/**👇编译器生成了属性方法列表： _OBJC_$_PROP_LIST_CategotyModel_$_ZH
*/
static struct /*_prop_list_t*/ {
    unsigned int entsize;  // sizeof(struct _prop_t)
    unsigned int count_of_properties;
    struct _prop_t prop_list[1];
} _OBJC_$_PROP_LIST_CategotyModel_$_ZH __attribute__ ((used, section ("__DATA,__objc_const"))) = {
    sizeof(_prop_t),
    1, // 👈属性个数
    {
        // 👇根据属性构造_prop_t结构体，若有多个属性依次向后加参数。
        // C: copy  N: nonatomic  V_cjmName: 实例变量【category不会生成实例变量】
        {"zh_name","T@\"NSString\",C,N"}
    }
};
```

### 用方法列表、属性列表初始化category本身，构造_category_t结构体

```C
extern "C" __declspec(dllexport) struct _class_t OBJC_CLASS_$_CategotyModel;

//👇编译器【用前面生成的列表】初始化category本身
/**
struct _category_t {
    const char *name;
    struct _class_t *cls;
    const struct _method_list_t *instance_methods;
    const struct _method_list_t *class_methods;
    const struct _protocol_list_t *protocols;
    const struct _prop_list_t *properties;
};
*/
static struct _category_t _OBJC_$_CATEGORY_CategotyModel_$_ZH __attribute__ ((used, section ("__DATA,__objc_const"))) =
{
    "CategotyModel", // 👈类名
    0, // &OBJC_CLASS_$_CategotyModel, //👈cls是要扩展的类对象，编译期间是不会定义的，而是在Runtime阶段通过name对应到对应的类对象
    (const struct _method_list_t *)&_OBJC_$_CATEGORY_INSTANCE_METHODS_CategotyModel_$_ZH, // 👈实例方法列表
    0, // 👈类方法列表
    0, // 👈协议列表
    (const struct _prop_list_t *)&_OBJC_$_PROP_LIST_CategotyModel_$_ZH, // 👈属性列表
};
```

### 为运行期初始化准备函数入口

```C
//👇静态函数：将category本身的class属性 指向原始被扩展的类
static void OBJC_CATEGORY_SETUP_$_CategotyModel_$_ZH(void ) {
    //👇&OBJC_CLASS_$_CategotyModel为原始类指针
    _OBJC_$_CATEGORY_CategotyModel_$_ZH.cls = &OBJC_CLASS_$_CategotyModel;
}

#pragma section(".objc_inithooks$B", long, read, write)
//👇运行期OBJC_CATEGORY_SETUP函数入口
__declspec(allocate(".objc_inithooks$B")) static void *OBJC_CATEGORY_SETUP[] = {
    // 👇将category本身的class属性 指向原始被扩展的类
    (void *)&OBJC_CATEGORY_SETUP_$_CategotyModel_$_ZH,
};

//👇将数组L_OBJC_LABEL_CLASS_$ [1] 放到__DATA段下的objc_catlist用于运行时的加载
static struct _class_t *L_OBJC_LABEL_CLASS_$ [1] __attribute__((used, section ("__DATA, __objc_classlist,regular,no_dead_strip")))= {
    //👇原始类指针
    &OBJC_CLASS_$_CategotyModel,
};

//👇将数组L_OBJC_LABEL_CATEGORY_$ [1] 放到__DATA段下的objc_catlist用于运行时的加载
static struct _category_t *L_OBJC_LABEL_CATEGORY_$ [1] __attribute__((used, section ("__DATA, __objc_catlist,regular,no_dead_strip")))= {
    //👇_category_t结构体指针
    &_OBJC_$_CATEGORY_CategotyModel_$_ZH,
};
static struct IMAGE_INFO { unsigned version; unsigned flag; } _OBJC_IMAGE_INFO = { 0, 2 };
```

编译器的工作到此结束

## Category加载

### OC运行时的入口函数（objc-os.mm文件）

```C
// lbz objc加载入口
void _objc_init(void)
{
    static bool initialized = false;
    if (initialized) return;
    initialized = true;

    // fixme defer initialization until an objc-using image is found?
    environ_init();
    tls_init();
    static_init();
    runtime_init();
    exception_init();
    cache_init();
    _imp_implementationWithBlock_init();

    /** lbz 👇 类的load方法在category初始化之后运行，
             因此可以在类的+load方法里面，调用category中声明的方法
    */
    /** lbz  👇objc image初始化工作
        map_images : category加载
        load_images： load方法加载
     */
    _dyld_objc_notify_register(&map_images, load_images, unmap_image);

#if __OBJC2__
    didCallDyldNotifyRegister = true;
#endif
}
```

> 方法调用
map_images --> map_images_nolock --> _read_images(hList, hCount, totalClasses, unoptimizedTotalClasses)
在_read_images函数中完成了大量的初始化操作，包括处理category。
了解更多戳👉 [Runtime加载过程:❌ 此部分还未总结](https://github.com/L-Zheng/ZHExample/blob/master/NoteBook/Runtime加载过程.md)

### runtime加载category

```C
void _read_images(){
    //...
    /** lbz  objc加载category */
    if (didInitialAttachCategories) {
        for (EACH_HEADER) {
            load_categories_nolock(hi);
        }
    }
    //...
}
```

### 从__DATA段读取存储的_category_t数组准备添加

```C
static void load_categories_nolock(header_info *hi) {
    bool hasClassProperties = hi->info()->hasCategoryClassProperties();

    size_t count;
    auto processCatlist = [&](category_t * const *catlist) {
        for (unsigned i = 0; i < count; i++) {
            category_t *cat = catlist[i];
            // lbz 👇获取category指向的原始类
            Class cls = remapClass(cat->cls);
            locstamped_category_t lc{cat, hi};

            if (!cls) {
                // Category's target class is missing (probably weak-linked).
                // Ignore the category.
                if (PrintConnecting) {
                    _objc_inform("CLASS: IGNORING category \?\?\?(%s) %p with "
                                 "missing weak-linked target class",
                                 cat->name, cat);
                }
                continue;
            }

            // Process this category.
            if (cls->isStubClass()) {
                // Stub classes are never realized. Stub classes
                // don't know their metaclass until they're
                // initialized, so we have to add categories with
                // class methods or properties to the stub itself.
                // methodizeClass() will find them and add them to
                // the metaclass as appropriate.
                if (cat->instanceMethods ||
                    cat->protocols ||
                    cat->instanceProperties ||
                    cat->classMethods ||
                    cat->protocols ||
                    (hasClassProperties && cat->_classProperties))
                {
                    // lbz 👇关联 原始类 和 category
                    objc::unattachedCategories.addForClass(lc, cls);
                }
            } else {
                // First, register the category with its target class.
                // Then, rebuild the class's method lists (etc) if
                // the class is realized.
                if (cat->instanceMethods ||  cat->protocols
                    ||  cat->instanceProperties)
                {
                    if (cls->isRealized()) {
                        // lbz 👇加载category
                        attachCategories(cls, &lc, 1, ATTACH_EXISTING);
                    } else {
                        // lbz 👇关联 原始类 和 category
                        objc::unattachedCategories.addForClass(lc, cls);
                    }
                }

                if (cat->classMethods  ||  cat->protocols
                    ||  (hasClassProperties && cat->_classProperties))
                {
                    if (cls->ISA()->isRealized()) {
                        // lbz 👇加载category
                        attachCategories(cls->ISA(), &lc, 1, ATTACH_EXISTING | ATTACH_METACLASS);
                    } else {
                        // lbz 👇关联 原始类 和 category
                        objc::unattachedCategories.addForClass(lc, cls->ISA());
                    }
                }
            }
        }
    };

    // lbz 👇获取 __DATA段存储的_category_t数组
    processCatlist(_getObjc2CategoryList(hi, &count));
    processCatlist(_getObjc2CategoryList2(hi, &count));
}
```

### 获取category_t中的方法列表 并 存储

```C
static void
attachCategories(Class cls, const locstamped_category_t *cats_list, uint32_t cats_count,
                 int flags)
{
    if (slowpath(PrintReplacedMethods)) {
        printReplacements(cls, cats_list, cats_count);
    }
    if (slowpath(PrintConnecting)) {
        _objc_inform("CLASS: attaching %d categories to%s class '%s'%s",
                     cats_count, (flags & ATTACH_EXISTING) ? " existing" : "",
                     cls->nameForLogging(), (flags & ATTACH_METACLASS) ? " (meta)" : "");
    }

    /*
     * Only a few classes have more than 64 categories during launch.
     * This uses a little stack, and avoids malloc.
     *
     * Categories must be added in the proper order, which is back
     * to front. To do that with the chunking, we iterate cats_list
     * from front to back, build up the local buffers backwards,
     * and call attachLists on the chunks. attachLists prepends the
     * lists, so the final result is in the expected order.
     */
    constexpr uint32_t ATTACH_BUFSIZ = 64;
    method_list_t   *mlists[ATTACH_BUFSIZ];
    property_list_t *proplists[ATTACH_BUFSIZ];
    protocol_list_t *protolists[ATTACH_BUFSIZ];

    uint32_t mcount = 0;
    uint32_t propcount = 0;
    uint32_t protocount = 0;
    bool fromBundle = NO;
    bool isMeta = (flags & ATTACH_METACLASS);
    auto rwe = cls->data()->extAllocIfNeeded();

    for (uint32_t i = 0; i < cats_count; i++) {
        auto& entry = cats_list[i];

        // lbz 👇获取某个category的方法列表
        method_list_t *mlist = entry.cat->methodsForMeta(isMeta);
        if (mlist) {
            if (mcount == ATTACH_BUFSIZ) {
                prepareMethodLists(cls, mlists, mcount, NO, fromBundle);
                rwe->methods.attachLists(mlists, mcount);
                mcount = 0;
            }
            // lbz 👇从最后一位开始插入元素
            mlists[ATTACH_BUFSIZ - ++mcount] = mlist;
            fromBundle |= entry.hi->isBundle();
        }

        // lbz 👇获取某个category的属性列表
        property_list_t *proplist =
            entry.cat->propertiesForMeta(isMeta, entry.hi);
        if (proplist) {
            if (propcount == ATTACH_BUFSIZ) {
                rwe->properties.attachLists(proplists, propcount);
                propcount = 0;
            }
            proplists[ATTACH_BUFSIZ - ++propcount] = proplist;
        }

        // lbz 👇获取某个category的协议列表
        protocol_list_t *protolist = entry.cat->protocolsForMeta(isMeta);
        if (protolist) {
            if (protocount == ATTACH_BUFSIZ) {
                rwe->protocols.attachLists(protolists, protocount);
                protocount = 0;
            }
            protolists[ATTACH_BUFSIZ - ++protocount] = protolist;
        }
    }

    if (mcount > 0) {
        prepareMethodLists(cls, mlists + ATTACH_BUFSIZ - mcount, mcount, NO, fromBundle);
        // lbz 👇追加方法列表到原始类中去
        rwe->methods.attachLists(mlists + ATTACH_BUFSIZ - mcount, mcount);
        // lbz 👇刷新缓存
        if (flags & ATTACH_EXISTING) flushCaches(cls);
    }

    rwe->properties.attachLists(proplists + ATTACH_BUFSIZ - propcount, propcount);

    rwe->protocols.attachLists(protolists + ATTACH_BUFSIZ - protocount, protocount);
}
```

### 追加方法列表到原始类中去

```C
void attachLists(List* const * addedLists, uint32_t addedCount) {
    if (addedCount == 0) return;

    if (hasArray()) {
        // many lists -> many lists
        // lbz 👇添加之前原来类中方法的个数
        uint32_t oldCount = array()->count;
        uint32_t newCount = oldCount + addedCount;
        setArray((array_t *)realloc(array(), array_t::byteSize(newCount)));
        array()->count = newCount;
        // lbz 👇将原来的方法列表向后移动 新加方法的个数
        memmove(array()->lists + addedCount, array()->lists,
                oldCount * sizeof(array()->lists[0]));
        // lbz 👇将新加方法 拷贝到原来方法列表的前面
        memcpy(array()->lists, addedLists,
                addedCount * sizeof(array()->lists[0]));
    }
    else if (!list  &&  addedCount == 1) {
        // 0 lists -> 1 list
        list = addedLists[0];
    }
    else {
        // 1 list -> many lists
        List* oldList = list;
        uint32_t oldCount = oldList ? 1 : 0;
        uint32_t newCount = oldCount + addedCount;
        setArray((array_t *)malloc(array_t::byteSize(newCount)));
        array()->count = newCount;
        if (oldList) array()->lists[addedCount] = oldList;
        memcpy(array()->lists, addedLists,
                addedCount * sizeof(array()->lists[0]));
    }
}
```

> **以上得出结论：category的方法没有“完全替换掉”原来类已经有的方法，在方法列表中，category的方法位于列表的前面，运行时在查找方法时顺着方法列表的顺序查找，只要一找到对应名字的方法，就会停止。因此方法调用优先级Category-->本类-->父类**

## load方法

[load方法加载顺序](https://github.com/L-Zheng/ZHExample/blob/master/NoteBook/✅+load与+initialize.md)

## 如何调用被覆盖的方法

用运行时获取当前类的所有方法，调用方法列表的最后一个方法。

```Objective-C
Class currentClass = [MyClass class];
MyClass *my = [[MyClass alloc] init];
if (currentClass) {
    unsigned int methodCount;
    Method *methodList = class_copyMethodList(currentClass, &methodCount);
    IMP lastImp = NULL;
    SEL lastSel = NULL;
    for (NSInteger i = 0; i < methodCount; i++) {
        Method method = methodList[i];
        NSString *methodName = [NSString stringWithCString:sel_getName(method_getName(method))  encoding:NSUTF8StringEncoding];
        if ([@"printName" isEqualToString:methodName]) {
            lastImp = method_getImplementation(method);
            lastSel = method_getName(method);
        }
    }
    typedef void (*fn)(id,SEL);

    if (lastImp != NULL) {
        fn f = (fn)lastImp;
        f(my,lastSel);
    }
    free(methodList);
}
```

## 使用关联对象为Category添加属性

```Objective-C
/** _cmd 代表该方法 */
-(NSString *)zh_name{
    return objc_getAssociatedObject(self, _cmd);
}
/** @selector 中的方法表示 该属性的get方法 */
-(void)setZh_name:(NSString *)zh_name{
    objc_setAssociatedObject(self, @selector(zh_name), zh_name, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
```

### runtime如何处理关联对象

runtime的源码，在objc-references.mm文件中有个方法_object_set_associative_reference

```C
void _object_set_associative_reference(id object, const void *key, id value, uintptr_t policy)
{
    // This code used to work when nil was passed for object and key. Some code
    // probably relies on that to not crash. Check and handle it explicitly.
    // rdar://problem/44094390
    if (!object && !value) return;

    if (object->getIsa()->forbidsAssociatedObjects())
        _objc_fatal("objc_setAssociatedObject called on instance (%p) of class %s which does not allow associated objects", object, object_getClassName(object));

    DisguisedPtr<objc_object> disguised{(objc_object *)object};
    ObjcAssociation association{policy, value};

    // retain the new value (if any) outside the lock.
    association.acquireValue();

    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.get());

        if (value) {
            auto refs_result = associations.try_emplace(disguised, ObjectAssociationMap{});
            if (refs_result.second) {
                /* it's the first association we make */
                object->setHasAssociatedObjects();
            }

            /* establish or replace the association */
            auto &refs = refs_result.first->second;
            auto result = refs.try_emplace(key, std::move(association));
            if (!result.second) {
                association.swap(result.first->second);
            }
        } else {
            auto refs_it = associations.find(disguised);
            if (refs_it != associations.end()) {
                auto &refs = refs_it->second;
                auto it = refs.find(key);
                if (it != refs.end()) {
                    association.swap(it->second);
                    refs.erase(it);
                    if (refs.size() == 0) {
                        associations.erase(refs_it);

                    }
                }
            }
        }
    }

    // release the old value (outside of the lock).
    association.releaseHeldValue();
}
```

AssociationsManager的定义如下

```C
class AssociationsManager {
    using Storage = ExplicitInitDenseMap<DisguisedPtr<objc_object>, ObjectAssociationMap>;
    static Storage _mapStorage;

public:
    AssociationsManager()   { AssociationsManagerLock.lock(); }
    ~AssociationsManager()  { AssociationsManagerLock.unlock(); }

    AssociationsHashMap &get() {
        return _mapStorage.get();
    }

    static void init() {
        _mapStorage.init();
    }
};
```

> AssociationsManager里面是由一个静态AssociationsHashMap来存储所有的关联对象的。这相当于把所有对象的关联对象都存在一个全局map里面。而map的的key是这个对象的指针地址（任意两个不同对象的指针地址一定是不同的），而这个map的value又是另外一个AssociationsHashMap，里面保存了关联对象的kv对。

```C
/** lbz 👇 AssociationsManager定义
 AssociationsManager --> AssociationsHashMap
 AssociationsHashMap：    @{
                         object(p%):     AssociationsHashMap：@{
                                                         @"key": @"value"
                                                        }
                     }
 */
```

### 清理关联对象：objc-runtime-new.mm文件

```C
void *objc_destructInstance(id obj)
{
    if (obj) {
        // Read all of the flags at once for performance.
        bool cxx = obj->hasCxxDtor();
        bool assoc = obj->hasAssociatedObjects();

        // This order is important.
        if (cxx) object_cxxDestruct(obj);
        /** lbz 👇 category关联对象的销毁 */
        if (assoc) _object_remove_assocations(obj);
        obj->clearDeallocating();
    }

    return obj;
}
```

runtime的销毁对象函数objc_destructInstance里面会判断这个对象有没有关联对象，如果有，会调用_object_remove_assocations做关联对象的清理工作

## 系统的哪些类用到了Category

```Objective-C
JSContext
- (JSValue *)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;
UIView
+ (void)animateWithDuration:
```

## 参考文章

[参考1](https://tech.meituan.com/2015/03/03/diveintocategory.html)
