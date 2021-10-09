# SQLite.swift 文档


### 手动安装

要将SQLite.swift安装为Xcode的一个子项目。

 1. 拖动**SQLite.xcodeproj**文件到你自己的项目中。([子模块](http://git-scm.com/book/en/Git-Tools-Submodules), 克隆，或[下载](https://github.com/stephencelis/SQLite.swift/archive/master.zip)该项目首先。)

![安装屏幕截图](https://github.com/stephencelis/SQLite.swift/blob/master/Documentation/Resources/installation@2x.png)

 2. 在你的目标的**常规**标签中，点击**链接的框架和库下的**+**按钮。

 3. 为你的平台选择合适的**SQLite.framework**。

 4. **添加**。

现在你应该能够从任何目标的源文件中`导入SQLite`并开始使用SQLite.swift。

在实际设备上安装应用程序还需要一些额外的步骤。

 5. 在**通用**标签中，点击**嵌入式二进制文件下的**+**按钮。

 6. 为你的平台选择合适的**SQLite.framework**。

 7. **添加**。

## 入门

要在目标的源文件中使用SQLite.swift类或结构，首先要导入`SQLite`模块。

```swift
import SQLite
```

### 连接到一个数据库

数据库的连接是通过`Connection`类建立的。一个连接被初始化为一个数据库的路径。如果数据库文件不存在，SQLite将尝试创建该文件。

```swift
let db = try Connection("path/to/db.sqlite3")
```

#### 读写数据库

在iOS上，你可以在你的应用程序的**Documents**目录下创建一个可写数据库。

```swift
let path = NSSearchPathForDirectoriesInDomains(
    .documentDirectory, .userDomainMask, true
).first!

let db = try Connection("\(path)/db.sqlite3")
```

如果你在你的应用程序中捆绑了它，你可以使用FileManager把它复制到Documents目录:

```swift
func copyDatabaseIfNeeded(sourcePath: String) -> Bool {
    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    let destinationPath = documents + "/db.sqlite3"
    let exists = FileManager.default.fileExists(atPath: destinationPath)
    guard !exists else { return false }
    do {
        try FileManager.default.copyItem(atPath: sourcePath, toPath: destinationPath)
        return true
    } catch {
      print("error during file copy: \(error)")
	    return false
    }
}
```

在MacOS上，你可以使用你的应用程序的**应用程序支持**目录。

```swift
var path = NSSearchPathForDirectoriesInDomains(
    .applicationSupportDirectory, .userDomainMask, true
).first! + "/" + Bundle.main.bundleIdentifier!

// create parent directory iff it doesn’t exist
try FileManager.default.createDirectory(
atPath: path, withIntermediateDirectories: true, attributes: nil
)

let db = try Connection("\(path)/db.sqlite3")
```

#### 只读数据库

如果您将数据库与您的应用程序捆绑在一起（即，您已经复制了一个数据库文件到您的Xcode项目并将其添加到您的应用程序目标），您可以建立一个 _只读_ 连接到它。

```swift
let path = Bundle.main.pathForResource("db", ofType: "sqlite3")!

let db = try Connection(path, readonly: true)
```

> 注意：已签名的应用程序不能修改其捆绑资源。如果你为了引导而将数据库文件与你的应用程序捆绑在一起，那么在建立连接之前，请将其复制到一个可写的位置（关于典型的可写位置，请参见上文[读写数据库](#read-write-databases)）。
>
> 请参阅Stack Overflow的这两个问题，了解有关iOS应用程序与SQLite数据库的更多信息。[1](https://stackoverflow.com/questions/34609746/what-different-between-store-database-in-different-locations-in-ios), [2](https://stackoverflow.com/questions/34614968/ios-how-to-copy-pre-seeded-database-at-the-first-running-app-with-sqlite-swift). 
>
> 我们欢迎对上述示例代码进行修改，以展示如何成功地复制和使用捆绑的 "种子 "数据库在应用程序中进行写入。

#### 内存数据库

如果你省略了路径，SQLite.swift将提供一个[内存数据库](https://www.sqlite.org/inmemorydb.html)。

```swift
let db = try Connection() // equivalent to `Connection(.inMemory)`
```

要创建一个临时的、以磁盘为基础的数据库，请传递一个空文件名。

```swift
let db = try Connection(.temporary)
```

当数据库连接关闭时，内存中的数据库会被自动删除。

#### 线程安全

每个连接都配备了自己的串行队列，用于语句的执行，并且可以跨线程安全访问。打开事务和保存点的线程将阻止其他线程在事务打开时执行语句。

如果你为一个数据库维护多个连接，可以考虑设置一个超时（以秒为单位）*或*一个繁忙处理程序。一次只能有一个活动，所以设置一个繁忙处理程序将有效地覆盖`busyTimeout`。

```swift
db.busyTimeout = 5 // error after 5 seconds (does multiple retries)

db.busyHandler({ tries in
    tries < 3  // error after 3 tries
})
```

> 注意：默认超时为0，所以如果你看到 "数据库被锁定 "的错误，你可能试图从多个连接同时访问同一个数据库。

## 构建类型安全的SQL

SQLite.swift带有一个类型化表达层，可以直接将[Swift类型](https://developer.apple.com/library/prerelease/ios/documentation/General/Reference/SwiftStandardLibraryReference/)映射到它们的[SQLite对应类型](https://www.sqlite.org/datatype3.html)。

| Swift Type    | SQLite Type |
| ------------- | ----------- |
| `Int64`*      | `INTEGER`   |
| `Double`      | `REAL`      |
| `String`      | `TEXT`      |
| `nil`         | `NULL`      |
| `SQLite.Blob` | `BLOB`      |

> 虽然`Int64`是基本的、原始的类型（在32位平台上保留64位整数），但`Int`和`Bool`是透明地工作。
>
> SQLite.swift定义了它自己的`Blob`结构，它安全地包装了底层字节。
>
> 参见[自定义类型](#custom-types)，了解更多关于扩展其他类和结构以与SQLite.swift协同工作的信息。
>
> 参见 [Executing Arbitrary-sql](#executing-arbitrary-sql)，以放弃类型化层，转而执行原始SQL。

这些表达式（以结构形式，[`表达式`](#表达式)）相互建立，并通过查询（[`QueryType`](#queries)），可以创建和执行SQL语句。

### 表达式

表达式是与一个类型（[内置](#building-type-safe-sql)或[自定义](#custom-types)）、原始SQL以及与该SQL绑定的值（可选）相关的通用结构。通常情况下，你只会显式地创建表达式来描述你的列，而且通常每列只有一次
列。

```swift
let id = Expression<Int64>("id")
let email = Expression<String>("email")
let balance = Expression<Double>("balance")
let verified = Expression<Bool>("verified")
```

对于可以评估为`NULL'的表达式，使用可选的泛型。

```swift
let name = Expression<String?>("name")
```

> 注意：默认的`表达式`初始化器是针对[带引号的标识符](https://www.sqlite.org/lang_keywords.html)（即_，列名）。要建立一个字面的SQL表达式，使用`init(literal:)`。
> <！--FIXME -->

### 复合表达式

表达式可以使用[过滤操作符和函数](#filter-operators-and-functions)（以及其他[非过滤操作符](#other-operators)和[函数](#core-sqlite-functions)）与其他表达式和类型结合。这些构建模块可以创建复杂的SQLite语句。


### 查询

查询是引用数据库和表名的结构，可以使用表达式来构建各种语句。我们可以通过初始化一个 "表"、"视图 "或 "虚拟表 "来创建一个查询。

```swift
let users = Table("users")
```

假设[表存在](#creating-a-table)，我们可以立即[插入](#inserting-rows)，[选择](#selecting-rows)，[更新](#updating-rows)，和[删除](#deleting-rows)行。

## 创建一个表

我们可以通过在一个 "表"上调用 "create"函数来建立[`CREATE TABLE`语句](https://www.sqlite.org/lang_createtable.html)。下面是一个SQLite.swift代码的基本例子（使用上面的[expressions](#expressions)和[query](#queries)）和它生成的相应SQL。

```swift
try db.run(users.create { t in     // CREATE TABLE "users" (
    t.column(id, primaryKey: true) //     "id" INTEGER PRIMARY KEY NOT NULL,
    t.column(email, unique: true)  //     "email" TEXT UNIQUE NOT NULL,
    t.column(name)                 //     "name" TEXT
})                                 // )
```

>  注意：`表达式<T>`结构（在本例中，`id`和`email`列），自动生成`NOT NULL`约束，而`表达式<T?>`结构（`name`）不会。

### 创建表选项

`Table.create`函数有几个默认参数，我们可以覆盖。

  - `temporary`在`CREATE TABLE`语句中加入`TEMPORARY`子句（创建一个临时表，当数据库连接关闭时自动放弃）。默认：`false`。

```swift
try db.run(users.create(temporary: true) { t in /* ... */ })
// CREATE TEMPORARY TABLE "users" -- ...
```

- `ifNotExists'在`CREATE TABLE'语句中增加了一个`IF NOT EXISTS'子句（如果表已经存在，将从容退出）。
    语句（如果表已经存在，将优雅地跳出）。
    默认：`false`。

```swift
try db.run(users.create(ifNotExists: true) { t in /* ... */ })
// CREATE TABLE "users" IF NOT EXISTS -- ...
```

### 列的限制条件

`column`函数用于单个列的定义。它接收一个描述列名和类型的[expression](#expressions)，并接受若干参数，这些参数映射到各种列约束和条款。

- `primaryKey`为一个单列添加`PRIMARY KEY`约束。

```swift
t.column(id, primaryKey: true)
// "id" INTEGER PRIMARY KEY NOT NULL

t.column(id, primaryKey: .autoincrement)
// "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL
```

> 注意: `primaryKey`参数不能与`references`一起使用。如果你需要创建一个有默认值的列，同时也是主键和/或外键，请使用[表约束](#table-constraints)中提到的`primaryKey`和`foreignKey`函数。
>
> 主键不能是可选的(_e.g._, `Expression<Int64?>`)。
>
> 只有`INTEGER PRIMARY KEY`可以采取`.autoincrement`。

- `unique`为该列添加一个`UNIQUE`约束。(参见[表约束](#表约束)下的`unique`功能，以实现多列的唯一性)。

```swift
t.column(email, unique: true)
// "email" TEXT UNIQUE NOT NULL
```

- `check`以布尔表达式（`Expression<Bool>`）的形式将`CHECK`约束附加到列的定义中。布尔表达式可以使用[过滤器操作符和函数](#filter-operators-and-functions)轻松建立。(也请参见[表约束](#table-constraints)下的`check`函数)。

```swift
t.column(email, check: email.like("%@%"))
// "email" TEXT NOT NULL CHECK ("email" LIKE '%@%')
```

- `defaultValue`在列的定义中添加了一个`DEFAULT`子句，_只接受一个与该列类型相匹配的值（或表达式）。如果在[一个`INSERT`](#inserting-rows)过程中没有明确提供任何值，则使用该值。

```swift
t.column(name, defaultValue: "Anonymous")
// "name" TEXT DEFAULT 'Anonymous'
```

> 注意：`defaultValue`参数不能与`primaryKey`和`references`同时使用。如果你需要创建一个有默认值的列，同时也是主键和/或外键，请使用[表约束](#table-constraints)中提到的`primaryKey`和`foreignKey`函数。

- `collate`为`Expression<String>`(和`Expression<String?>`)列定义添加`COLLATE`子句，并在`Collation`枚举中定义了[整理序列](https://www.sqlite.org/datatype3.html#collation)。

```swift
t.column(email, collate: .nocase)
// "email" TEXT NOT NULL COLLATE "NOCASE"

t.column(name, collate: .rtrim)
// "name" TEXT COLLATE "RTRIM"
```

- `references`为`Expression<Int64>`(和`Expression<Int64?>`)的列定义添加`REFERENCES`子句，并接受表(`SchemaType`)或命名的列表达。(关于非整数外键支持，请参见[表约束](#表约束)下的`foreignKey`功能)。

```swift
t.column(user_id, references: users, id)
// "user_id" INTEGER REFERENCES "users" ("id")
```

> 注意: `references`参数不能与`primaryKey`和`defaultValue`同时使用。如果你需要创建一个有默认值的列，同时也是主键和/或外键，请使用[表约束](#table-constraints)中提到的`primaryKey`和`foreignKey`函数。

### 表的约束条件

可以使用以下函数在单列的范围之外提供额外的约束。

  - `primaryKey`为表添加一个`PRIMARY KEY`约束。与[上面的列约束](#column-constraints)不同，它支持所有SQLite类型，[升序和降序](#sorting-rows)，以及复合(多列)键。

```swift
t.primaryKey(email.asc, name)
// PRIMARY KEY("email" ASC, "name")
```

- `unique`给表添加一个`UNIQUE`约束。与[上面的列约束](#column-constraints)不同，它支持复合（多列）约束。

```swift
t.unique(local, domain)
// UNIQUE("local", "domain")
```

- `check`以布尔表达式(`Expression<Bool>`)的形式向表添加一个`CHECK`约束。布尔表达式可以使用[过滤器操作符和函数](#filter-operators-and-functions)轻松建立。(也可以参见[列约束](#column-constraints)下的`检查'参数)。

```swift
t.check(balance >= 0)
// CHECK ("balance" >= 0.0)
```

- `foreignKey`给表添加了一个`FOREIGN KEY`约束。与[上面的`references`约束](#column-constraints)不同，它支持所有SQLite类型，支持[`ON UPDATE`和`ON DELETE`动作](https://www.sqlite.org/foreignkeys.html#fk_actions)，以及复合(多列)键。

```swift
t.foreignKey(user_id, references: users, id, delete: .setNull)
// FOREIGN KEY("user_id") REFERENCES "users"("id") ON DELETE SET NULL
```

## 插入行

我们可以通过调用一个[query](#queries)`insert`函数来向表中插入行，该函数带有一个[setters](#setters)的列表--通常是[类型化的列表达式](#expressions)和值(也可以是表达式)--每个都由`<-`操作员连接。

```swift
try db.run(users.insert(email <- "alice@mac.com", name <- "Alice"))
// INSERT INTO "users" ("email", "name") VALUES ('alice@mac.com', 'Alice')

try db.run(users.insert(or: .replace, email <- "alice@mac.com", name <- "Alice B."))
// INSERT OR REPLACE INTO "users" ("email", "name") VALUES ('alice@mac.com', 'Alice B.')
```

`insert`函数，当运行成功时，返回一个`Int64`代表被插入行的[ROWID](https://sqlite.org/lang_createtable.html#rowid)。

```swift
do {
    let rowid = try db.run(users.insert(email <- "alice@mac.com"))
    print("inserted id: \(rowid)")
} catch {
    print("insertion failed: \(error)")
}
```

通过类似于调用`insertMany`和一个每行[setters](#setters)的数组，可以一次插入多行。

```swift
do {
    let lastRowid = try db.run(users.insertMany([email <- "alice@mac.com"], [email <- "geoff@mac.com"]))
    print("last inserted id: \(lastRowid)")
} catch {
    print("insertion failed: \(error)")
}
```

[`update`](#updating-rows)和[`delete`](#deleting-rows)函数遵循类似模式。

> 注意：如果`insert`被调用而没有任何参数，语句将以`DEFAULT VALUES`子句运行。该表不能有任何默认值不满足的约束。
>
> ```swift
> try db.run(timestamps.insert())
> // INSERT INTO "timestamps" DEFAULT VALUES
> ```

### 处理SQLite错误

你可以在错误上进行模式匹配来有选择地捕捉SQLite错误。例如，要专门处理约束错误[SQLITE_CONSTRAINT](https://sqlite.org/rescode.html#constraint)。

```swift
do {
    try db.run(users.insert(email <- "alice@mac.com"))
    try db.run(users.insert(email <- "alice@mac.com"))
} catch let Result.error(message, code, statement) where code == SQLITE_CONSTRAINT {
    print("constraint failed: \(message), in \(statement)")
} catch let error {
    print("insertion failed: \(error)")
}
```

`Result.error`类型包含描述错误的英文文本（`message`），错误`代码`详见[SQLite结果代码列表](https://sqlite.org/rescode.html#primary_result_code_list)和对产生错误的`statement`的可选引用。

### 设置器

SQLite.swift通常使用`<-`操作符在[插入](#inserting-rows)和[更新](#updating-rows)期间设置值。

```swift
try db.run(counter.update(count <- 0))
// UPDATE "counters" SET "count" = 0 WHERE ("id" = 1)
```

还有一些方便的设置器，使用本地Swift操作符考虑到现有的值。

例如，为了原子化地增加一列，我们可以使用`++`。

```swift
try db.run(counter.update(count++)) // equivalent to `counter.update(count -> count + 1)`
// UPDATE "counters" SET "count" = "count" + 1 WHERE ("id" = 1)
```

为了获取一个金额并通过交易 "移动" 它，我们可以使用`-=`和`+=`。

```swift
let amount = 100.0
try db.transaction {
    try db.run(alice.update(balance -= amount))
    try db.run(betty.update(balance += amount))
}
// BEGIN DEFERRED TRANSACTION
// UPDATE "users" SET "balance" = "balance" - 100.0 WHERE ("id" = 1)
// UPDATE "users" SET "balance" = "balance" + 100.0 WHERE ("id" = 2)
// COMMIT TRANSACTION
```

###### Infix Setters

| Operator | Types              |
| -------- | ------------------ |
| `<-`     | `Value -> Value`   |
| `+=`     | `Number -> Number` |
| `-=`     | `Number -> Number` |
| `*=`     | `Number -> Number` |
| `/=`     | `Number -> Number` |
| `%=`     | `Int -> Int`       |
| `<<=`    | `Int -> Int`       |
| `>>=`    | `Int -> Int`       |
| `&=`     | `Int -> Int`       |
| `\|\|=`  | `Int -> Int`       |
| `^=`     | `Int -> Int`       |
| `+=`     | `String -> String` |

###### Postfix Setters

| Operator | Types        |
| -------- | ------------ |
| `++`     | `Int -> Int` |
| `--`     | `Int -> Int` |

## 选择行

[查询结构](#queries)是等待发生的`SELECT`语句。它们通过[迭代](#iterating-and-accessing-values)和[其他手段](#plucking-values)的序列访问来执行。


### 迭代和访问值

准备好的[查询](#queries)在迭代时懒洋洋地执行。每一行都作为一个`Row'对象被返回，它可以用一个与返回的列之一相匹配的[列表达式](#expressions)来下标。

```swift
for user in try db.prepare(users) {
    print("id: \(user[id]), email: \(user[email]), name: \(user[name])")
    // id: 1, email: alice@mac.com, name: Optional("Alice")
}
// SELECT * FROM "users"
```

`Expression<T>`列的值是_自动解包的_（我们已经向编译器承诺，它们永远不会是`NULL'），而`Expression<T?>`的值仍然被包起来。

⚠ `Row`上的列下标将强制尝试并在错误情况下中止执行。

如果你想自己处理这个问题，请使用`Row.get(_ column: Expression<V>)`。

```swift
for user in try db.prepare(users) {
    do {
        print("name: \(try user.get(name))")
    } catch {
        // handle
    }
}
```

请注意，迭代器可以在迭代的任何时候抛出*undeclared*数据库错误。

```swift
let query = try db.prepare(users)
for user in query {
    // 💥 can throw an error here
}
````

#### 失败的迭代

因此建议使用`RowIterator`API，它有明确的错误处理。

```swift
// option 1: convert results into an Array of rows
let rowIterator = try db.prepareRowIterator(users)
for user in try Array(rowIterator) {
    print("id: \(user[id]), email: \(user[email])")
}

/// option 2: transform results using `map()`
let mapRowIterator = try db.prepareRowIterator(users)
let userIds = try mapRowIterator.map { $0[id] }

/// option 3: handle each row individually with `failableNext()`
do {
    while let row = try rowIterator.failableNext() {
        // Handle row
    }
} catch {
    // Handle error
}
```

### 拔取行

我们可以通过向数据库连接上的`pluck`函数传递一个查询来提取第一行。

```swift
if let user = try db.pluck(users) { /* ... */ } // Row
// SELECT * FROM "users" LIMIT 1
```

为了将所有的行收集到一个数组中，我们可以简单地将序列包裹起来（尽管这并不总是最节省内存的想法）。

```swift
let all = Array(try db.prepare(users))
// SELECT * FROM "users"
```

### 建立复杂的查询

[查询](#queries)有一些可连锁的函数，可以用来(与[表达式](#expressions)一起)增加和修改底层语句的[若干子句](https://www.sqlite.org/lang_select.html)。

```swift
let query = users.select(email)           // SELECT "email" FROM "users"
                 .filter(name != nil)     // WHERE "name" IS NOT NULL
                 .order(email.desc, name) // ORDER BY "email" DESC, "name"
                 .limit(5, offset: 1)     // LIMIT 5 OFFSET 1
```

#### 选择列

默认情况下，[query](#queries)选择结果集的每一列（使用`SELECT *`）。我们可以使用`select`函数和一个[expressions](#expressions)的列表来返回特定的列来代替。

```swift
for user in try db.prepare(users.select(id, email)) {
    print("id: \(user[id]), email: \(user[email])")
    // id: 1, email: alice@mac.com
}
// SELECT "id", "email" FROM "users"
```

我们可以通过抓住表达式本身的引用来访问更复杂的表达式的结果。

```swift
let sentence = name + " is " + cast(age) as Expression<String?> + " years old!"
for user in users.select(sentence) {
    print(user[sentence])
    // Optional("Alice is 30 years old!")
}
// SELECT ((("name" || 'is') || CAST ("age" AS TEXT)) || 'years old!') FROM "users"
```

#### 连接其他表

我们可以使用[query's](#queries) `join`函数来连接表。

```swift
users.join(posts, on: user_id == users[id])
// SELECT * FROM "users" INNER JOIN "posts" ON ("user_id" = "users"."id")
```

`join`函数接收一个[query](#queries)对象（用于被连接的表），一个连接条件（`on`），并以一个可选的连接类型（默认：`.inner`）为前缀。连接条件可以使用[过滤器操作符和函数](#filter-operators-and-functions)来建立，通常需要[命名间距](#column-namespacing)，有时需要[别名](#table-aliasing)。


##### 列名间距

当连接表时，列名可能变得模糊不清。例如，两个表都可能有一个id列。

```swift
let query = users.join(posts, on: user_id == id)
// assertion failure: ambiguous column 'id'
```

我们可以通过对`id`进行命名来消除歧义。

```swift
let query = users.join(posts, on: user_id == users[id])
// SELECT * FROM "users" INNER JOIN "posts" ON ("user_id" = "users"."id")
```

命名是通过用[列表达式](#表达式)对[查询](#查询)进行下标来实现的（例如_，上面的`users[id]`变成`users.id`）。

> 注意：我们可以使用`*`对一个表的所有列进行命名。
>```swift
> let query = users.select(users[*])
> // SELECT "users".* FROM "users"
> ```

##### 表的别名

偶尔，我们需要将一个表连接到它自己，在这种情况下，我们必须用另一个名字来别名该表。我们可以使用[query's](#queries) `alias`函数来实现这一目的。

```swift
let managers = users.alias("managers")

let query = users.join(managers, on: managers[id] == users[managerId])
// SELECT * FROM "users"
// INNER JOIN ("users") AS "managers" ON ("managers"."id" = "users"."manager_id")
```

如果查询结果可能有不明确的列名，那么应该用命名的[列表达式](#expressions)来访问行值。在上述情况下，`SELECT *`立即对结果集的所有列进行命名。

```swift
let user = try db.pluck(query)
user[id]           // fatal error: ambiguous column 'id'
                   // (please disambiguate: ["users"."id", "managers"."id"])

user[users[id]]    // returns "users"."id"
user[managers[id]] // returns "managers"."id"
```

#### 过滤行

SQLite.swift使用[query's](#queries)`filter`函数和一个布尔[expression](#expressions)(`Expression<Bool>`)来过滤行。

```swift
users.filter(id == 1)
// SELECT * FROM "users" WHERE ("id" = 1)

users.filter([1, 2, 3, 4, 5].contains(id))
// SELECT * FROM "users" WHERE ("id" IN (1, 2, 3, 4, 5))

users.filter(email.like("%@mac.com"))
// SELECT * FROM "users" WHERE ("email" LIKE '%@mac.com')

users.filter(verified && name.lowercaseString == "alice")
// SELECT * FROM "users" WHERE ("verified" AND (lower("name") == 'alice'))

users.filter(verified || balance >= 10_000)
// SELECT * FROM "users" WHERE ("verified" OR ("balance" >= 10000.0))
```

我们可以通过使用许多[过滤器操作符和函数](#filter-operators-and-functions)中的一个来建立我们自己的布尔表达式。

我们也可以使用`filter`来代替`where`函数，这是一个别名。

```swift
users.where(id == 1)
// SELECT * FROM "users" WHERE ("id" = 1)
```

##### 过滤操作符和函数

SQLite.swift定义了一些用于构建过滤谓词的操作符。操作符和函数以类型安全的方式一起工作，所以试图等同或比较不同的类型会阻止编译。


###### Infix 过滤操作符

| Swift  | Types                            | SQLite         |
| ------ | -------------------------------- | -------------- |
| `==`   | `Equatable -> Bool`              | `=`/`IS`*      |
| `!=`   | `Equatable -> Bool`              | `!=`/`IS NOT`* |
| `>`    | `Comparable -> Bool`             | `>`            |
| `>=`   | `Comparable -> Bool`             | `>=`           |
| `<`    | `Comparable -> Bool`             | `<`            |
| `<=`   | `Comparable -> Bool`             | `<=`           |
| `~=`   | `(Interval, Comparable) -> Bool` | `BETWEEN`      |
| `&&`   | `Bool -> Bool`                   | `AND`          |
| `\|\|` | `Bool -> Bool`                   | `OR`           |
| `===`  | `Equatable -> Bool`              | `IS`           |
| `!==`  | `Equatable -> Bool`              | `IS NOT`       |

> 当与`nil`进行比较时，SQLite.swift将相应地使用`IS`和`IS NOT`。

###### 前缀过滤运算符

| Swift | Types          | SQLite |
| ----- | -------------- | ------ |
| `!`   | `Bool -> Bool` | `NOT`  |

###### 过滤功能

| Swift      | Types                   | SQLite  |
| ---------- | ----------------------- | ------- |
| `like`     | `String -> Bool`        | `LIKE`  |
| `glob`     | `String -> Bool`        | `GLOB`  |
| `match`    | `String -> Bool`        | `MATCH` |
| `contains` | `(Array<T>, T) -> Bool` | `IN`    |

#### 对行进行排序

我们可以使用[query's](#queries) `order`函数对返回的行进行预排序。

例如，按`email`排序，然后按`name`排序，升序返回用户。

```swift
users.order(email, name)
// SELECT * FROM "users" ORDER BY "email", "name"
```

`order`函数接收一个[列表达式](#expressions)的列表。

`表达式`对象有两个计算属性来帮助排序。`asc`和`desc`。这些属性在表达式上附加`ASC`和`DESC`，分别标记升序和降序。

```swift
users.order(email.desc, name.asc)
// SELECT * FROM "users" ORDER BY "email" DESC, "name" ASC
```

#### 限制和分页结果

我们可以使用[query](#queries)的`limit`函数（及其可选的`offset`参数）限制和跳过返回的行。

```swift
users.limit(5)
// SELECT * FROM "users" LIMIT 5

users.limit(5, offset: 5)
// SELECT * FROM "users" LIMIT 5 OFFSET 5
```

#### 聚合

[查询](#queries)带有一些函数，可以快速从表中返回聚合标量值。这些函数反映了[核心聚合函数](#aggregate-sqlite-functions)，并立即针对查询执行。

```swift
let count = try db.scalar(users.count)
// SELECT count(*) FROM "users"
```

过滤后的查询将适当地过滤汇总值。

```swift
let count = try db.scalar(users.filter(name != nil).count)
// SELECT count(*) FROM "users" WHERE "name" IS NOT NULL
```

- `count'作为一个查询的计算属性（见上面的例子）返回 匹配该查询的总行数。

	`count'作为一个列表达式的计算属性，返回该列不是`NULL'的总行数。列不是`NULL'的行的总数。

 ```swift
 let count = try db.scalar(users.select(name.count)) // -> Int
 // SELECT count("name") FROM "users"
 ```

- `max`接收一个可比较的列表达式，如果有的话，返回最大的值。

```swift
let max = try db.scalar(users.select(id.max)) // -> Int64?
// SELECT max("id") FROM "users"
```

- `min`接收一个可比较的列表达式，如果有的话，返回最小的值。

```swift
let min = try db.scalar(users.select(id.min)) // -> Int64?
// SELECT min("id") FROM "users"
```

- `average`接收一个数字列表达式，并返回平均行值（作为一个`Double`），如果有的话。

```swift
let average = try db.scalar(users.select(balance.average)) // -> Double?
// SELECT avg("balance") FROM "users"
```

- `sum`接收一个数字列表达式，如果有的话，返回所有行的总和。

```swift
let sum = try db.scalar(users.select(balance.sum)) // -> Double?
// SELECT sum("balance") FROM "users"
```

- `total`和`sum`一样，接受一个数字列表达式并返回所有行的总和，但在这种情况下总是返回一个`Double`，如果是空查询则返回`0.0`。

```swift
let total = try db.scalar(users.select(balance.total)) // -> Double
// SELECT total("balance") FROM "users"
```

>  注意：通过调用`distinct`计算属性，表达式可以在前面加上`DISTINCT`子句。
>```swift
> let count = try db.scalar(users.select(name.distinct.count) // -> Int
> // SELECT count(DISTINCT "name") FROM "users"
> ```

## 颠覆行

我们可以通过调用一个[query](#queries)`upsert`函数将行上移到表中，该函数带有一个[setters](#setters)的列表--通常是[类型化的列表达式](#expressions)和值(也可以是表达式)--每个都由`<-`操作员连接。upserting和inserting一样，只是如果在指定的列值上有冲突，SQLite将对该行进行更新。

```swift
try db.run(users.upsert(email <- "alice@mac.com", name <- "Alice"), onConflictOf: email)
// INSERT INTO "users" ("email", "name") VALUES ('alice@mac.com', 'Alice') ON CONFLICT (\"email\") DO UPDATE SET \"name\" = \"excluded\".\"name\"
```

`upsert`函数，当运行成功时，返回一个`Int64`，代表插入行的[`ROWID`](https://sqlite.org/lang_createtable.html#rowid)。

```swift
do {
    let rowid = try db.run(users.upsert(email <- "alice@mac.com", name <- "Alice", onConflictOf: email))
    print("inserted id: \(rowid)")
} catch {
    print("insertion failed: \(error)")
}
```

[`insert`](#inserting-rows), [`update`](#updating-rows), 和 [`delete`](#deleting-rows)函数遵循类似的模式。

## 更新行

我们可以通过调用一个[query](#queries)`update`函数来更新表的行，该函数带有一个[setters](#setters)的列表--通常是[类型化的列表达式](#expressions)和值(也可以是表达式)--每个都由`<-`操作员连接。

当一个无范围的查询调用`update`时，它将更新表中的每一条记录。

```swift
try db.run(users.update(email <- "alice@me.com"))
// UPDATE "users" SET "email" = 'alice@me.com'
```

请确保事先使用[`过滤`功能](#filtering-rows)对`UPDATE`语句进行范围化处理。

```swift
let alice = users.filter(id == 1)
try db.run(alice.update(email <- "alice@me.com"))
// UPDATE "users" SET "email" = 'alice@me.com' WHERE ("id" = 1)
```

`update`函数返回一个`Int`，代表更新的行数。

```swift
do {
    if try db.run(alice.update(email <- "alice@me.com")) > 0 {
        print("updated alice")
    } else {
        print("alice not found")
    }
} catch {
    print("update failed: \(error)")
}
```

## 删除行

我们可以通过调用[query](#queries)的`delete`函数，从表中删除行。

当一个无范围的查询调用`delete`时, 它将删除表中的每一条记录.

```swift
try db.run(users.delete())
// DELETE FROM "users"
```

请确保事先使用[`filter`函数](#filtering-rows)对`DELETE`语句进行范围控制。

```swift
let alice = users.filter(id == 1)
try db.run(alice.delete())
// DELETE FROM "users" WHERE ("id" = 1)
```

`delete`函数返回一个`Int`，代表被删除的行数。

```swift
do {
    if try db.run(alice.delete()) > 0 {
        print("deleted alice")
    } else {
        print("alice not found")
    }
} catch {
    print("delete failed: \(error)")
}
```

## 交易和保存点

使用`transaction`和`savepoint`函数，我们可以在一个事务中运行一系列的语句。如果有一条语句失败了，或者该块出现了错误，那么这些变化将被回滚。

```swift
try db.transaction {
    let rowid = try db.run(users.insert(email <- "betty@icloud.com"))
    try db.run(users.insert(email <- "cathy@icloud.com", managerId <- rowid))
}
// BEGIN DEFERRED TRANSACTION
// INSERT INTO "users" ("email") VALUES ('betty@icloud.com')
// INSERT INTO "users" ("email", "manager_id") VALUES ('cathy@icloud.com', 2)
// COMMIT TRANSACTION
```

> 注意：交易在一个串行队列中运行。

## 改变模式

SQLite.swift带有几个函数（除了`Table.create`），用于以一种类型安全的方式改变数据库模式。


### 重命名表

我们可以通过在一个 "表 "或 "虚拟表 "上调用 "重命名 "函数来建立一个 "ALTER TABLE ... RENAME TO "语句。

```swift
try db.run(users.rename(Table("users_old")))
// ALTER TABLE "users" RENAME TO "users_old"
```

### 添加列

我们可以通过在 "表 "上调用 "addColumn "函数来向表添加列。SQLite.swift执行的是SQLite支持的`ALTER TABLE`的[相同的有限子集](https://www.sqlite.org/lang_altertable.html)。

```swift
try db.run(users.addColumn(suffix))
// ALTER TABLE "users" ADD COLUMN "suffix" TEXT
```

#### 已添加的列约束条件

`addColumn`函数与[创建表](#creating-a-table)时使用的[`column`函数参数](#column-constraints)相同。

  - `check`以布尔表达式(`Expression<Bool>`)的形式给列定义附加一个`CHECK`约束。(参见[表约束](#table-constraints)下的`check'函数)。

```swift
try db.run(users.addColumn(suffix, check: ["JR", "SR"].contains(suffix)))
// ALTER TABLE "users" ADD COLUMN "suffix" TEXT CHECK ("suffix" IN ('JR', 'SR'))
```

`defaultValue`在列的定义中添加了一个`DEFAULT`子句，并且只接受一个与该列类型相匹配的值。如果在[一个`INSERT`](#inserting-rows)过程中没有明确提供任何值，则使用此值。

```swift
try db.run(users.addColumn(suffix, defaultValue: "SR"))
// ALTER TABLE "users" ADD COLUMN "suffix" TEXT DEFAULT 'SR'
```

> 注意：与[`CREATE TABLE`约束](#table-constraints)不同，默认值不能是表达式结构（包括`CURRENT_TIME`, `CURRENT_DATE`, 或`CURRENT_TIMESTAMP`）。

`collate`为`Expression<String>`(和`Expression<String?>`)列定义添加`COLLATE`子句，并在`Collation`枚举中定义了[整理序列](https://www.sqlite.org/datatype3.html#collation)。

 ```swift
 try db.run(users.addColumn(email, collate: .nocase))
 // ALTER TABLE "users" ADD COLUMN "email" TEXT NOT NULL COLLATE "NOCASE"
 
 try db.run(users.addColumn(name, collate: .rtrim))
 // ALTER TABLE "users" ADD COLUMN "name" TEXT COLLATE "RTRIM"
 ```

- `references`为`Int64`(和`Int64?`)列定义添加`REFERENCES`子句，并接受表或命名的列表达。(关于非整数外键支持，请参见[表约束](#表约束)下的`foreignKey`功能)。

```swift
try db.run(posts.addColumn(userId, references: users, id)
// ALTER TABLE "posts" ADD COLUMN "user_id" INTEGER REFERENCES "users" ("id")
```

### 重命名列

在SQLite 3.25.0中添加，目前尚未公开。[#1073](https://github.com/stephencelis/SQLite.swift/issues/1073)

### 丢弃列

已在SQLite 3.35.0中添加，还未公开。[#1073](https://github.com/stephencelis/SQLite.swift/issues/1073)

### 索引


#### 创建索引

我们可以通过在`SchemaType`上调用`createIndex`函数来建立[`CREATE INDEX`语句](https://www.sqlite.org/lang_createindex.html)。

```swift
try db.run(users.createIndex(email))
// CREATE INDEX "index_users_on_email" ON "users" ("email")
```

索引名称是根据表和列名自动生成的。

`createIndex`函数有几个默认参数，我们可以覆盖。

  - `unique`给索引添加一个`UNIQUE`约束。默认：`false`。

```swift
try db.run(users.createIndex(email, unique: true))
// CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email")
```

- `ifNotExists`在`CREATE TABLE`语句中增加一个`IF NOT EXISTS`子句（如果表已经存在，将优雅地跳出）。默认值: `false`.

```swift
try db.run(users.createIndex(email, ifNotExists: true))
// CREATE INDEX IF NOT EXISTS "index_users_on_email" ON "users" ("email")
```

#### 删除索引

我们可以通过在一个`SchemaType`上调用`dropIndex`函数来建立[`DROP INDEX`语句](https://www.sqlite.org/lang_dropindex.html)。

```swift
try db.run(users.dropIndex(email))
// DROP INDEX "index_users_on_email"
```

`dropIndex`函数有一个额外的参数，`ifExists`，它（当`true`时）在语句中增加一个`IF EXISTS`子句。

```swift
try db.run(users.dropIndex(email, ifExists: true))
// DROP INDEX IF EXISTS "index_users_on_email"
```

### 丢弃表

我们可以通过在一个`SchemaType`上调用`dropTable`函数来建立[`DROP TABLE`语句](https://www.sqlite.org/lang_droptable.html)。

```swift
try db.run(users.drop())
// DROP TABLE "users"
```

`drop`函数有一个额外的参数，`ifExists`，它（当`true`时）在语句中添加一个`IF EXISTS`子句。

```swift
try db.run(users.drop(ifExists: true))
// DROP TABLE IF EXISTS "users"
```

### 迁移和模式版本控制

你可以在`Connection`上添加一个方便的属性来查询和设置[`PRAGMA user_version`](https://sqlite.org/pragma.html#pragma_user_version)。

这是一个很好的方法来管理你的模式在迁移中的版本。

```swift
extension Connection {
    public var userVersion: Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as! Int64)}
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}
```

然后，你可以按照以下思路有条件地运行你的迁移。

```swift
if db.userVersion == 0 {
    // handle first migration
    db.userVersion = 1
}
if db.userVersion == 1 {
    // handle second migration
    db.userVersion = 2
}
```

对于更复杂的迁移要求，请查看模式管理系统[SQLiteMigrationManager.swift](https://github.com/garriguv/SQLiteMigrationManager.swift)。

## 自定义类型

SQLite.swift支持序列化和反序列化任何自定义类型，只要它符合`Value`协议。

```swift
protocol Value {
    typealias Datatype: Binding
    class var declaredDatatype: String { get }
    class func fromDatatypeValue(datatypeValue: Datatype) -> Self
    var datatypeValue: Datatype { get }
}
```

`Datatype`必须是基本的Swift类型之一，数值在序列化和反序列化之前会通过这些类型进行桥接（类型列表见[构建类型安全的SQL](#building-type-secure-sql)）。

> 注意：`Binding`是SQLite.swift内部使用的一个协议，用于直接将SQLite类型映射到Swift类型。**不要**让自定义类型符合`Binding`协议。

### 日期-时间值

在SQLite中，`DATETIME'列可以被视为字符串或数字，所以我们可以通过Swift的`String'类型透明地连接`Date'对象。

我们可以在SQLite语句中直接使用这些类型。

```swift
let published_at = Expression<Date>("published_at")

let published = posts.filter(published_at <= Date())
// SELECT * FROM "posts" WHERE "published_at" <= '2014-11-18T12:45:30.000'

let startDate = Date(timeIntervalSince1970: 0)
let published = posts.filter(startDate...Date() ~= published_at)
// SELECT * FROM "posts" WHERE "published_at" BETWEEN '1970-01-01T00:00:00.000' AND '2014-11-18T12:45:30.000'
```

### 二进制数据

我们可以桥接任何可以从`数据'初始化并编码的类型。

```swift
extension UIImage: Value {
    public class var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    public class func fromDatatypeValue(blobValue: Blob) -> UIImage {
        return UIImage(data: Data.fromDatatypeValue(blobValue))!
    }
    public var datatypeValue: Blob {
        return UIImagePNGRepresentation(self)!.datatypeValue
    }

}
```

> 注意：请参阅[档案和序列化编程指南](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Archiving/Archiving.html)以了解更多关于编码和解码自定义类型的信息。

## 可编码类型

[可编码类型](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types))是作为Swift 4的一部分引入的，以允许序列化和反序列化类型。SQLite.swift 支持基本 Codable 类型的插入、更新和检索。

### 插入可编码类型

查询有一个方法，允许插入一个[可编码](https://developer.apple.com/documentation/swift/encodable)类型。


```swift
struct User: Encodable {
    let name: String
}
try db.run(users.insert(User(name: "test")))
```

这个方法还有另外两个参数可用。

- `userInfo`是一个字典，它被传递给编码器，并提供给可编码类型，以允许自定义其行为。

- `otherSetters'允许你在可编码类型本身产生的设置之外指定额外的设置。

### 更新可编码类型

查询有一个方法允许更新一个可编码类型。

```swift
try db.run(users.filter(id == userId).update(user))
```

除非经过过滤，在Codable类型的实例上使用更新方法会更新所有的表行。

这个方法还有另外两个参数可用。

- `userInfo`是一个字典，它被传递给编码器，并提供给可编码类型，以允许自定义其行为。

- `otherSetters`允许你在可编码类型本身产生的设置之外指定额外的设置。

### 检索可编码类型

行有一个方法来解码一个[Decodable](https://developer.apple.com/documentation/swift/decodable)类型。

```swift
let loadedUsers: [User] = try db.prepare(users).map { row in
    return try row.decode()
}
```

你也可以自己手动创建一个解码器来使用。例如，如果你使用[Facade模式](https://en.wikipedia.org/wiki/Facade_pattern)将子类隐藏在超类后面，这可能很有用。例如，你可能想对一个可以是多种不同格式的图像类型进行编码，如PNGImage、JPGImage或HEIFImage。你需要先确定正确的子类，然后才知道要解码哪种类型。

```swift
enum ImageCodingKeys: String, CodingKey {
    case kind
}

enum ImageKind: Int, Codable {
    case png, jpg, heif
}

let loadedImages: [Image] = try db.prepare(images).map { row in
    let decoder = row.decoder()
    let container = try decoder.container(keyedBy: ImageCodingKeys.self)
    switch try container.decode(ImageKind.self, forKey: .kind) {
    case .png:
        return try PNGImage(from: decoder)
    case .jpg:
        return try JPGImage(from: decoder)
    case .heif:
        return try HEIFImage(from: decoder)
    }
}
```

上述两个方法也有以下可选参数。

- `userInfo`是一个字典，它被传递给解码器，并提供给可解码类型，以允许定制它们的行为。

### 限制条件

在使用Codable类型方面有一些限制。

- 可编码和可解码对象只能使用以下类型。
    - Int, Bool, Float, Double, String, Date
    - 嵌套的Codable类型，将被编码为JSON到一个单一列中
- 这些方法不会为你处理对象关系。如果你想支持这个，你必须编写你自己的Codable和Decodable实现。
- Codable类型不能尝试访问嵌套的容器或嵌套的无键容器
- Codable类型不能访问单值的容器或无键的容器
- 可编码类型不能访问超级解码器或编码器。

## 其他操作符

除了[过滤器操作符](#filtering-infix-operators)之外，SQLite.swift还定义了一些操作符，可以用算术、位操作和连接来修改表达式的值。

###### Other Infix Operators

| Swift | Types              | SQLite |
| ----- | ------------------ | ------ |
| `+`   | `Number -> Number` | `+`    |
| `-`   | `Number -> Number` | `-`    |
| `*`   | `Number -> Number` | `*`    |
| `/`   | `Number -> Number` | `/`    |
| `%`   | `Int -> Int`       | `%`    |
| `<<`  | `Int -> Int`       | `<<`   |
| `>>`  | `Int -> Int`       | `>>`   |
| `&`   | `Int -> Int`       | `&`    |
| `\|`  | `Int -> Int`       | `\|`   |
| `+`   | `String -> String` | `\|\|` |

> 注意：SQLite.swift也定义了一个位XOR操作符`^`，它将表达式`lhs ^ rhs`扩展为`~(lhs & rhs) & (lhs | rhs)`。

###### Other Prefix Operators

| Swift | Types              | SQLite |
| ----- | ------------------ | ------ |
| `~`   | `Int -> Int`       | `~`    |
| `-`   | `Number -> Number` | `-`    |

## 核心SQLite函数

许多SQLite的[核心函数](https://www.sqlite.org/lang_corefunc.html)已经在SQLite.swift中浮现并进行了类型审核。

> 注意：SQLite.swift将`??`操作符别名为`ifnull`函数。
> ```swift
> name ?? email // ifnull("name", "email")
> ```

## 聚合的SQLite函数

大多数SQLite的[聚合函数](https://www.sqlite.org/lang_aggfunc.html)已经在SQLite.swift中浮出水面并进行了类型审核。

## 日期和时间函数

SQLite的[日期和时间](https://www.sqlite.org/lang_datefunc.html)函数是可用的。

```swift
DateFunctions.date("now")
// date('now')
Date().date
// date('2007-01-09T09:41:00.000')
Expression<Date>("date").date
// date("date")
```

## 自定义SQL函数

我们可以通过在数据库连接上调用`createFunction`来创建自定义SQL函数。

例如，为了让查询访问[`MobileCoreServices.UTTypeConformsTo`](https://developer.apple.com/documentation/coreservices/1444079-uttypeconformsto)，我们可以写如下。

```swift
import MobileCoreServices

let typeConformsTo: (Expression<String>, Expression<String>) -> Expression<Bool> = (
    try db.createFunction("typeConformsTo", deterministic: true) { UTI, conformsToUTI in
        return UTTypeConformsTo(UTI, conformsToUTI)
    }
)
```

> 注意：可选的`deterministic`参数是一种优化，使函数在创建时带有[`SQLITE_DETERMINISTIC`](https://www.sqlite.org/c3ref/c_deterministic.html)。

注意`typeConformsTo`的签名。

```swift
(Expression<String>, Expression<String>) -> Expression<Bool>
```

正因为如此，`createFunction'期望一个具有以下签名的块。

```swift
(String, String) -> Bool
```

一旦被分配，闭包可以在任何接受布尔表达式的地方被调用。

```swift
let attachments = Table("attachments")
let UTI = Expression<String>("UTI")

let images = attachments.filter(typeConformsTo(UTI, kUTTypeImage))
// SELECT * FROM "attachments" WHERE "typeConformsTo"("UTI", 'public.image')
```

> 注意：函数的返回类型必须是[核心SQL类型](#building-type-safe-sql)或[符合`Value`](#custom-types)。

我们可以通过处理一个原始参数的数组来创建松散类型的函数。

```swift
db.createFunction("typeConformsTo", deterministic: true) { args in
    guard let UTI = args[0] as? String, conformsToUTI = args[1] as? String else { return nil }
    return UTTypeConformsTo(UTI, conformsToUTI)
}
```

创建一个松散类型的函数不能返回一个闭包，而必须手动包装或执行[使用原始SQL](#executing-arbitrary-sql)。

```swift
let stmt = try db.prepare("SELECT * FROM attachments WHERE typeConformsTo(UTI, ?)")
for row in stmt.bind(kUTTypeImage) { /* ... */ }
```

## 自定义聚合

我们可以通过调用`createAggregation`来创建自定义聚合函数。

```swift
let reduce: (String, [Binding?]) -> String = { (last, bindings) in
    last + " " + (bindings.first as? String ?? "")
}

db.createAggregation("customConcat", initialValue: "", reduce: reduce, result: { $0 })
let result = db.prepare("SELECT customConcat(email) FROM users").scalar() as! String
```

## 自定义排列组合

我们可以通过在数据库连接上调用`createCollation'来创建自定义整理序列。

```swift
try db.createCollation("NODIACRITIC") { lhs, rhs in
    return lhs.compare(rhs, options: .diacriticInsensitiveSearch)
}
```

我们可以使用`Collation'枚举的`Custom'成员来引用一个自定义整理。

```swift
restaurants.order(collate(.custom("NODIACRITIC"), name))
// SELECT * FROM "restaurants" ORDER BY "name" COLLATE "NODIACRITIC"
```

## 全文搜索

我们可以使用[FTS4模块](http://www.sqlite.org/fts3.html)创建一个虚拟表，在一个`虚拟表'上调用`create'。

```swift
let emails = VirtualTable("emails")
let subject = Expression<String>("subject")
let body = Expression<String>("body")

try db.run(emails.create(.FTS4(subject, body)))
// CREATE VIRTUAL TABLE "emails" USING fts4("subject", "body")
```

我们可以使用`tokenize`参数指定一个[tokenizer](http://www.sqlite.org/fts3.html#tokenizer)。

```swift
try db.run(emails.create(.FTS4([subject, body], tokenize: .Porter)))
// CREATE VIRTUAL TABLE "emails" USING fts4("subject", "body", tokenize=porter)
```

我们可以通过创建一个`FTS4Config`对象来设置全部参数。

```swift
let emails = VirtualTable("emails")
let subject = Expression<String>("subject")
let body = Expression<String>("body")
let config = FTS4Config()
    .column(subject)
    .column(body, [.unindexed])
    .languageId("lid")
    .order(.desc)

try db.run(emails.create(.FTS4(config))
// CREATE VIRTUAL TABLE "emails" USING fts4("subject", "body", notindexed="body", languageid="lid", order="desc")
```

一旦我们插入了几条记录，我们就可以使用`match`函数进行搜索，该函数将一个表或列作为第一个参数，将一个查询字符串作为第二个参数。

```swift
try db.run(emails.insert(
    subject <- "Just Checking In",
    body <- "Hey, I was just wondering...did you get my last email?"
))

let wonderfulEmails: QueryType = emails.match("wonder*")
// SELECT * FROM "emails" WHERE "emails" MATCH 'wonder*'

let replies = emails.filter(subject.match("Re:*"))
// SELECT * FROM "emails" WHERE "subject" MATCH 'Re:*'
```

### FTS5

当针对启用了[FTS5](http://www.sqlite.org/fts5.html)的SQLite版本进行链接时，我们可以以类似的方式创建虚拟表。

```swift
let emails = VirtualTable("emails")
let subject = Expression<String>("subject")
let body = Expression<String>("body")
let config = FTS5Config()
    .column(subject)
    .column(body, [.unindexed])

try db.run(emails.create(.FTS5(config)))
// CREATE VIRTUAL TABLE "emails" USING fts5("subject", "body" UNINDEXED)

// Note that FTS5 uses a different syntax to select columns, so we need to rewrite
// the last FTS4 query above as:
let replies = emails.filter(emails.match("subject:\"Re:\"*"))
// SELECT * FROM "emails" WHERE "emails" MATCH 'subject:"Re:"*'

// https://www.sqlite.org/fts5.html#_changes_to_select_statements_
```

## 执行任意的SQL

尽管我们建议你尽可能坚持使用SQLite.swift的[类型安全系统](#building-type-safe-sql)，但使用以下函数，通过`数据库`连接简单安全地准备和执行原始SQL语句是可能的。

  - `execute`作为一种方便，运行任意数量的SQL语句。

```swift
try db.execute("""
    BEGIN TRANSACTION;
    CREATE TABLE users (
        id INTEGER PRIMARY KEY NOT NULL,
        email TEXT UNIQUE NOT NULL,
        name TEXT
    );
    CREATE TABLE posts (
        id INTEGER PRIMARY KEY NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        published_at DATETIME
    );
    PRAGMA user_version = 1;
    COMMIT TRANSACTION;
    """
)
```

- `prepare`从一个SQL字符串中准备一个单一的`Statement`对象，可以选择将值绑定到它（使用语句的`bind`函数），并返回语句以延迟执行。

```swift
let stmt = try db.prepare("INSERT INTO users (email) VALUES (?)")
```

一旦准备好，就可以使用`run`来执行语句，绑定任何 未绑定的参数。

```swift
try stmt.run("alice@mac.com")
db.changes // -> {Some 1}
```

有结果的语句可以被迭代，如果有用的话，可以使用columnNames。

```swift
let stmt = try db.prepare("SELECT id, email FROM users")
for row in stmt {
    for (index, name) in stmt.columnNames.enumerated() {
        print ("\(name):\(row[index]!)")
        // id: Optional(1), email: Optional("alice@mac.com")
    }
}
```

- `run`从一个SQL字符串中准备一个单一的`Statement'对象，可以选择将值绑定到它（使用语句的`bind'函数），执行，并返回语句。

```swift
try db.run("INSERT INTO users (email) VALUES (?)", "alice@mac.com")
```

- `scalar'从一个SQL字符串中准备一个`Statement'对象，可以选择将值绑定到它（使用语句的`bind'函数），执行，并返回第一行的第一个值。

```swift
let count = try db.scalar("SELECT count(*) FROM users") as! Int64
```

语句也有一个`scalar'函数，它可以在执行时选择性地重新绑定数值。

```swift
let stmt = try db.prepare("SELECT count (*) FROM users")
let count = try stmt.scalar() as! Int64
```

## 在线数据库备份

要使用[SQLite Online Backup API](https://sqlite.org/backup.html)将一个数据库复制到另一个数据库。

```swift
// creates an in-memory copy of db.sqlite
let db = try Connection("db.sqlite")
let target = try Connection(.inMemory)

let backup = try db.backup(usingConnection: target)
try backup.step()
```

## 记录

我们可以使用数据库的`trace`函数来记录SQL。

```swift
#if DEBUG
    db.trace { print($0) }
#endif
```

## 真空

要运行[真空](https://www.sqlite.org/lang_vacuum.html)命令。

```swift
try db.vacuum()
```

