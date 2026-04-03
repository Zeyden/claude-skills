---
name: sqldelight-kmp
description: >
  Expert guide for working with SQLDelight 2.x in Kotlin Multiplatform projects.
  Use when asked to set up SQLDelight, write .sq files, configure drivers for any
  KMP target (Android, iOS, JVM, JS/WASM), handle migrations, integrate with Ktor,
  write coroutine/Flow queries, or debug SQLDelight issues in KMP.
---

# SQLDelight Expert Skill

> **SQLDelight** — generates typesafe Kotlin APIs from SQL statements. Validates
> schemas, statements, and migrations at compile time with full IDE support.
>
> Latest stable: **2.2.1** · Package group: `app.cash.sqldelight` · Kotlin 2.x · KMP

| Artifact | Coordinates |
|----------|------------|
| Runtime | `app.cash.sqldelight:runtime:2.2.1` |
| Coroutines extensions | `app.cash.sqldelight:coroutines-extensions:2.2.1` |
| Primitive adapters | `app.cash.sqldelight:primitive-adapters:2.2.1` |
| Android driver | `app.cash.sqldelight:android-driver:2.2.1` |
| Native driver (iOS/macOS/Linux) | `app.cash.sqldelight:native-driver:2.2.1` |
| JVM/Desktop driver | `app.cash.sqldelight:sqlite-driver:2.2.1` |
| JS web-worker driver | `app.cash.sqldelight:web-worker-driver:2.2.1` |
| Gradle plugin | `app.cash.sqldelight` (plugin ID) |

---

## 1 · Gradle Setup

### Version Catalogue (`gradle/libs.versions.toml`)

```toml
[versions]
sqldelight = "2.2.1"

[libraries]
sqldelight-runtime = { module = "app.cash.sqldelight:runtime", version.ref = "sqldelight" }
sqldelight-coroutines = { module = "app.cash.sqldelight:coroutines-extensions", version.ref = "sqldelight" }
sqldelight-primitive-adapters = { module = "app.cash.sqldelight:primitive-adapters", version.ref = "sqldelight" }
sqldelight-android-driver = { module = "app.cash.sqldelight:android-driver", version.ref = "sqldelight" }
sqldelight-native-driver = { module = "app.cash.sqldelight:native-driver", version.ref = "sqldelight" }
sqldelight-sqlite-driver = { module = "app.cash.sqldelight:sqlite-driver", version.ref = "sqldelight" }

[plugins]
sqldelight = { id = "app.cash.sqldelight", version.ref = "sqldelight" }
```

### Plugin Configuration (`shared/build.gradle.kts`)

```kotlin
plugins {
    alias(libs.plugins.sqldelight)
}

sqldelight {
    databases {
        create("AppDatabase") {
            packageName.set("com.example.data.local")
            // dialect("app.cash.sqldelight:sqlite-3-38-dialect:2.2.1")  // optional: unlock newer SQLite features
            // schemaOutputDirectory.set(file("src/commonMain/sqldelight/databases"))  // enable migration verification
            // verifyMigrations.set(true)
            // deriveSchemaFromMigrations.set(false)  // true = no .sq CREATE TABLE, schema from .sqm only
            // generateAsync.set(false)  // true = suspend query methods (required for JS web-worker-driver)
        }
    }
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation(libs.sqldelight.runtime)
            implementation(libs.sqldelight.coroutines)
            implementation(libs.sqldelight.primitive.adapters)
        }
        androidMain.dependencies {
            implementation(libs.sqldelight.android.driver)
        }
        iosMain.dependencies {
            implementation(libs.sqldelight.native.driver)
        }
        jvmMain.dependencies {  // Desktop
            implementation(libs.sqldelight.sqlite.driver)
        }
    }
}
```

### Key Gradle Options

| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `packageName` | `String` | — | Package for generated database class |
| `srcDirs` | `FileCollection` | `src/[prefix]main/sqldelight` | Folders containing `.sq`/`.sqm` files |
| `schemaOutputDirectory` | `Directory` | `null` | Where `.db` schema files go (enables migration verification) |
| `dialect` | `String` | SQLite 3.18 | Target SQL dialect (e.g., `sqlite-3-38-dialect` for JSON, window functions) |
| `verifyMigrations` | `Boolean` | `false` | Validate migration files during build |
| `deriveSchemaFromMigrations` | `Boolean` | `false` | Derive schema from `.sqm` instead of `.sq` |
| `generateAsync` | `Boolean` | `false` | Generate suspend query methods (required for JS/WASM) |
| `linkSqlite` | `Boolean` | `true` | Auto-link SQLite for native targets |

---

## 2 · Driver Setup Per Platform

### Common Interface (commonMain)

```kotlin
// commonMain
interface DatabaseDriverFactory {
    fun createDriver(): SqlDriver
}
```

### Android

```kotlin
// androidMain
class AndroidDatabaseDriverFactory(
    private val context: Context
) : DatabaseDriverFactory {
    override fun createDriver(): SqlDriver =
        AndroidSqliteDriver(
            schema = AppDatabase.Schema,
            context = context,
            name = "app.db"
        )
}
```

- Dialect auto-selected from `minSdkVersion`.
- `Context` is required — inject via DI.

### iOS / Native

```kotlin
// iosMain (or nativeMain)
class IosDatabaseDriverFactory : DatabaseDriverFactory {
    override fun createDriver(): SqlDriver =
        NativeSqliteDriver(
            schema = AppDatabase.Schema,
            name = "app.db",
            maxReaderConnections = 4  // concurrent read connections
        )
}
```

- **Requires Kotlin/Native new memory manager** (default since Kotlin 1.7.20, mandatory for SQLDelight 2.x).
- Reader connections are used only for queries outside transactions. Writes always use a single writer connection.
- **WAL mode is the default** on iOS/Native.
- **Xcode linker flag required:** Add `-lsqlite3` to Build Settings → Other Linker Flags.

### JVM / Desktop

```kotlin
// jvmMain
class DesktopDatabaseDriverFactory : DatabaseDriverFactory {
    override fun createDriver(): SqlDriver {
        val appDir = File(System.getProperty("user.home"), ".myapp")
        appDir.mkdirs()
        val dbFile = File(appDir, "app.db")
        return JdbcSqliteDriver(
            url = "jdbc:sqlite:${dbFile.absolutePath}",
            schema = AppDatabase.Schema,       // auto-creates + auto-migrates
            properties = Properties()
        )
    }
}
```

- Passing `schema` to the constructor handles creation and migration automatically via `PRAGMA user_version`.
- **WAL is NOT the default** on JVM — enable manually (see §8).
- `JdbcSqliteDriver.IN_MEMORY` for in-memory databases (testing).
- **Do NOT use `java.io.tmpdir`** for persistent databases — use user home or app data directory.

### JS / WASM (Browser)

Requires `generateAsync.set(true)` in Gradle config.

```kotlin
// jsMain
class JsDatabaseDriverFactory : DatabaseDriverFactory {
    // Note: must be suspend for async driver
    suspend fun createDriverAsync(): SqlDriver =
        WebWorkerDriver(
            Worker(
                js("""new URL("@cashapp/sqldelight-sqljs-worker/sqljs.worker.js", import.meta.url)""")
            )
        ).also { AppDatabase.Schema.awaitCreate(it) }
}
```

Additional npm dependencies required:
```kotlin
jsMain.dependencies {
    implementation(npm("@cashapp/sqldelight-sqljs-worker", "2.2.1"))
    implementation(npm("sql.js", "1.8.0"))
    implementation(devNpm("copy-webpack-plugin", "9.1.0"))
}
```

Webpack config (`webpack.config.d/sqljs.js`) needed to copy `sql-wasm.wasm` to output.

---

## 3 · Writing `.sq` Files

### File Location

`.sq` files go in: `src/commonMain/sqldelight/<package/path>/`

The sub-folder path **must match** the `packageName` in Gradle config. If it doesn't, no code is generated — and there are **no warnings**.

### Convention: One File Per Table

File name → generated `Queries` class name:
- `Player.sq` → `PlayerQueries`
- `Team.sq` → `TeamQueries`

Each file typically contains:
1. `import` statements for custom Kotlin types
2. `CREATE TABLE` statement
3. `CREATE INDEX` statements
4. Named queries (SELECT, INSERT, UPDATE, DELETE)

### Schema Definition

```sql
-- Player.sq
import kotlin.Boolean;
import kotlin.Int;
import com.example.domain.model.Position;

CREATE TABLE Player (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    number INTEGER AS Int NOT NULL,
    active INTEGER AS Boolean NOT NULL DEFAULT 1,
    position TEXT AS Position NOT NULL,
    team_id TEXT NOT NULL REFERENCES Team(id),
    created_at INTEGER NOT NULL  -- millis
);

CREATE INDEX idx_player_team ON Player(team_id);
CREATE INDEX idx_player_active ON Player(active) WHERE active = 1;
```

### SQL-to-Kotlin Type Mapping

| SQL Type | Kotlin Type | Notes |
|----------|-------------|-------|
| `INTEGER` | `Long` | Default. Use `AS Int`, `AS Short`, `AS Boolean` with primitive-adapters |
| `REAL` | `Double` | Use `AS Float` with primitive-adapters |
| `TEXT` | `String` | |
| `BLOB` | `ByteArray` | |

Primitive types (`Int`, `Short`, `Float`, `Boolean`) require:
- `import kotlin.Int;` (etc.) in the `.sq` file
- `app.cash.sqldelight:primitive-adapters` dependency
- Adapter registration: `IntColumnAdapter`, `ShortColumnAdapter`, `FloatColumnAdapter`

### Named Queries

```sql
-- SELECT queries
selectAll:
SELECT * FROM Player;

selectById:
SELECT * FROM Player WHERE id = :id;

selectByTeam:
SELECT * FROM Player WHERE team_id = ? AND active = 1;

selectWithJoin:
SELECT p.*, t.name AS team_name
FROM Player p
INNER JOIN Team t ON p.team_id = t.id
WHERE p.active = 1
ORDER BY p.name ASC;

countByTeam:
SELECT COUNT(*) FROM Player WHERE team_id = :teamId;

-- INSERT
insert:
INSERT INTO Player(id, name, number, active, position, team_id, created_at)
VALUES (?, ?, ?, ?, ?, ?, ?);

insertOrReplace:
INSERT OR REPLACE INTO Player(id, name, number, active, position, team_id, created_at)
VALUES (?, ?, ?, ?, ?, ?, ?);

-- UPDATE
updateName:
UPDATE Player SET name = :name WHERE id = :id;

deactivate:
UPDATE Player SET active = 0 WHERE id = :id;

-- DELETE
deleteById:
DELETE FROM Player WHERE id = :id;

deleteAll:
DELETE FROM Player;
```

### Bind Arguments

- **Indexed:** `?` — positional, mapped to function parameters in declaration order.
- **Named:** `:name` or `?` — named parameters generate readable Kotlin parameter names.
- **SQLite limit:** Max 999 bind variables per prepared statement. Chunk bulk operations.

### Cross-Table Queries

Queries in any `.sq` file can reference tables defined in other files. Place JOIN queries in the "primary" entity's file, or create a dedicated query file (e.g., `ReportQueries.sq` — no `CREATE TABLE`, only queries).

### Naming Convention

Table names directly affect generated class names:
- `trans_history` → `Trans_history` (ugly)
- `TransHistory` → `TransHistory` (clean)

**Always use PascalCase for table names.**

---

## 4 · Custom Column Types & Adapters

### Enum Columns (Built-in Adapter)

```sql
-- In .sq file
import com.example.domain.model.Position;

CREATE TABLE Player (
    position TEXT AS Position NOT NULL
);
```

```kotlin
// When creating the database
val database = AppDatabase(
    driver = driver,
    playerAdapter = Player.Adapter(
        positionAdapter = EnumColumnAdapter()
    )
)
```

`EnumColumnAdapter` stores the enum's `name` as TEXT and decodes via `valueOf()`.

### Custom ColumnAdapter

```kotlin
// Store List<String> as comma-separated TEXT
val listOfStringsAdapter = object : ColumnAdapter<List<String>, String> {
    override fun decode(databaseValue: String): List<String> =
        if (databaseValue.isEmpty()) emptyList()
        else databaseValue.split(",")

    override fun encode(value: List<String>): String =
        value.joinToString(",")
}
```

### JSON Adapter (with kotlinx.serialization)

```kotlin
class JsonColumnAdapter<T>(
    private val serializer: KSerializer<T>,
    private val json: Json = Json { ignoreUnknownKeys = true }
) : ColumnAdapter<T, String> {
    override fun decode(databaseValue: String): T =
        json.decodeFromString(serializer, databaseValue)
    override fun encode(value: T): String =
        json.encodeToString(serializer, value)
}

// Usage:
val metadataAdapter = JsonColumnAdapter(Metadata.serializer())
```

### Value Types

```sql
CREATE TABLE Player (
    id INT AS VALUE  -- generates a wrapper value class
);
```

### Registering Adapters

All adapters are passed when constructing the database instance:

```kotlin
val database = AppDatabase(
    driver = driver,
    playerAdapter = Player.Adapter(
        positionAdapter = EnumColumnAdapter(),
        numberAdapter = IntColumnAdapter
    )
)
```

---

## 5 · Coroutines & Flow Integration

### Dependency

```kotlin
commonMain.dependencies {
    implementation("app.cash.sqldelight:coroutines-extensions:2.2.1")
}
```

### Observing Queries as Flow

```kotlin
val players: Flow<List<Player>> =
    playerQueries.selectAll()
        .asFlow()                    // Query → Flow<Query<Player>>
        .mapToList(Dispatchers.IO)   // Flow<Query<Player>> → Flow<List<Player>>
```

**Available mapping operators:**

| Operator | Returns | Use When |
|----------|---------|----------|
| `mapToList(context)` | `Flow<List<T>>` | Query returns 0..N rows |
| `mapToOne(context)` | `Flow<T>` | Query always returns exactly 1 row |
| `mapToOneOrNull(context)` | `Flow<T?>` | Query returns 0 or 1 row |

**Dispatcher is mandatory** — always pass `Dispatchers.IO` (or a custom IO dispatcher). Omitting it is a compile error in 2.x.

### Reactive Update Mechanism

The Flow **automatically re-emits** whenever the underlying table is modified (INSERT, UPDATE, DELETE). This is notification-based — SQLDelight tracks which tables a query touches and invalidates when those tables change.

### Repository Pattern with Flow

```kotlin
class PlayerRepository(private val queries: PlayerQueries) {

    fun observeAll(): Flow<List<Player>> =
        queries.selectAll(::mapToPlayer)
            .asFlow()
            .mapToList(Dispatchers.IO)

    fun observeById(id: String): Flow<Player?> =
        queries.selectById(id, ::mapToPlayer)
            .asFlow()
            .mapToOneOrNull(Dispatchers.IO)

    // Non-reactive one-shot query
    suspend fun getAll(): List<Player> = withContext(Dispatchers.IO) {
        queries.selectAll(::mapToPlayer).executeAsList()
    }

    suspend fun insert(player: Player) = withContext(Dispatchers.IO) {
        queries.insert(
            id = player.id,
            name = player.name,
            // ...
        )
    }
}
```

### ViewModel Integration (StateFlow)

```kotlin
class PlayerListViewModel(private val repository: PlayerRepository) {
    val players: StateFlow<List<Player>> =
        repository.observeAll()
            .stateIn(
                scope = viewModelScope,
                started = SharingStarted.WhileSubscribed(5_000),
                initialValue = emptyList()
            )
}
```

---

## 6 · Transactions

### Basic Transaction

```kotlin
database.playerQueries.transaction {
    players.forEach { player ->
        database.playerQueries.insert(
            id = player.id,
            name = player.name,
            number = player.number,
            // ...
        )
    }
}
```

All statements execute atomically — all succeed or all roll back.

### Transaction with Return Value

```kotlin
val count: Long = database.playerQueries.transactionWithResult {
    database.playerQueries.deleteInactive()
    database.playerQueries.countAll().executeAsOne()
}
```

### Rollback

```kotlin
database.playerQueries.transaction {
    database.playerQueries.insert(/* ... */)
    if (somethingWrong) rollback()  // aborts entire transaction
}

database.playerQueries.transactionWithResult {
    if (invalid) rollback(0L)  // rollback with return value
    database.playerQueries.countAll().executeAsOne()
}
```

### Callbacks

```kotlin
database.playerQueries.transaction {
    afterCommit { log("Transaction committed") }
    afterRollback { log("Transaction rolled back") }
    // ... statements
}
```

### Batch Insert Performance

Wrapping inserts in a transaction is the **single biggest performance win**. Without a transaction, each INSERT is auto-committed with an fsync to disc. A transaction batches all writes.

```kotlin
// Chunk for SQLite's 999 bind-variable limit
items.chunked(250).forEach { chunk ->  // 4 columns x 250 = 1000, stay under 999
    database.itemQueries.transaction {
        chunk.forEach { item ->
            database.itemQueries.insert(item.id, item.name, item.value, item.category)
        }
    }
}
```

---

## 7 · Migrations

### File Structure

```
src/commonMain/sqldelight/
├── com/example/data/local/
│   ├── Player.sq
│   └── Team.sq
└── migrations/
    ├── 1.sqm    -- upgrades version 1 → 2
    ├── 2.sqm    -- upgrades version 2 → 3
    └── 3.sqm    -- upgrades version 3 → 4
```

The initial schema version is **1**. Migration files are named `<version_to_upgrade_from>.sqm`.

### Migration File Content

```sql
-- 1.sqm: upgrade from v1 to v2
ALTER TABLE Player ADD COLUMN draft_year INTEGER;
ALTER TABLE Player ADD COLUMN draft_order INTEGER;
```

**Critical:** Do NOT wrap migrations in `BEGIN/END TRANSACTION` — some drivers crash. The framework manages transactions automatically.

### Schema Version

Version is computed as: `number of .sqm files + 1`. There is no explicit version number declaration.

### Code-Based Data Migrations

```kotlin
AppDatabase.Schema.migrate(
    driver = driver,
    oldVersion = 0,
    newVersion = AppDatabase.Schema.version,
    AfterVersion(3) { driver ->
        // Runs after 3.sqm completes, before 4.sqm starts
        driver.execute(null, "UPDATE Player SET active = 1 WHERE active IS NULL", 0)
    }
)
```

### Migration Verification

1. Set `schemaOutputDirectory` in Gradle config.
2. Generate baseline: `./gradlew generate<SourceSet><DatabaseName>Schema` → produces `1.db`.
3. `verifySqlDelightMigration` Gradle task runs automatically with `check` — applies all migrations from `1.db` and confirms the result matches the current `.sq` schema.

### Best Practices

- Generate a `.db` file **before** your first migration.
- Keep one `1.db` baseline — most projects only need the original schema snapshot.
- Use `IF NOT EXISTS` on `CREATE INDEX` in migrations for idempotency.
- Test migrations against real data, not just schema compatibility.

---

## 8 · Platform Configuration Best Practices

### WAL Mode & PRAGMAs

```kotlin
// Call after driver creation (Android and JVM — iOS defaults to WAL)
fun configurePragmas(driver: SqlDriver) {
    driver.execute(null, "PRAGMA journal_mode=WAL;", 0)
    driver.execute(null, "PRAGMA synchronous=NORMAL;", 0)  // safe in WAL mode
    driver.execute(null, "PRAGMA foreign_keys=ON;", 0)
}
```

| Platform | WAL Default | Action |
|----------|-------------|--------|
| iOS/Native | Yes (via SQLiter) | No action needed |
| Android | No (historically) | Enable manually |
| JVM/Desktop | No | Enable manually |

`WAL + synchronous=NORMAL` is corruption-safe in WAL mode and avoids fsync on most writes. This is the recommended combination for local-first apps.

### Reader Connection Pools

| Platform | Support | Configuration |
|----------|---------|---------------|
| iOS/Native | Built-in | `maxReaderConnections = 4` in `NativeSqliteDriver` |
| JVM/Desktop | Single connection | `JdbcSqliteDriver` is essentially single-connection |
| Android | Via `AndroidSqliteDriver` callbacks | Or use `sqldelight-androidx-driver` for configurable concurrency |

---

## 9 · Testing

### In-Memory Driver (JVM tests)

```kotlin
// In jvmTest
fun createTestDriver(): SqlDriver {
    val driver = JdbcSqliteDriver(JdbcSqliteDriver.IN_MEMORY)
    AppDatabase.Schema.create(driver)
    return driver
}

@Test
fun testInsertAndSelect() {
    val driver = createTestDriver()
    val database = AppDatabase(driver, /* adapters */)
    val queries = database.playerQueries

    queries.insert(id = "1", name = "Wayne Gretzky", /* ... */)
    val player = queries.selectById("1").executeAsOne()

    assertEquals("Wayne Gretzky", player.name)
    driver.close()
}
```

### Testing with Flows

Use Turbine to test Flow emissions:

```kotlin
@Test
fun testReactiveUpdates() = runTest {
    val driver = createTestDriver()
    val database = AppDatabase(driver, /* adapters */)
    val queries = database.playerQueries

    queries.selectAll()
        .asFlow()
        .mapToList(UnconfinedTestDispatcher(testScheduler))
        .test {
            assertEquals(emptyList(), awaitItem())  // initial emission

            queries.insert(id = "1", name = "Test Player", /* ... */)
            val updated = awaitItem()
            assertEquals(1, updated.size)

            cancelAndIgnoreRemainingEvents()
        }
}
```

### Testing Migrations

The `verifySqlDelightMigration` Gradle task validates schema compatibility. For data migration testing, write integration tests that:
1. Create a database at version N.
2. Insert test data.
3. Run migrations to version N+1.
4. Verify data integrity.

---

## 10 · Performance

### Indexing in `.sq` Files

```sql
-- Basic index on foreign key
CREATE INDEX idx_player_team_id ON Player(team_id);

-- Composite index (most selective column first)
CREATE INDEX idx_translated_cue ON TranslatedCue(translation_id, cue_id);

-- Partial index (only indexes matching rows — smaller, faster)
CREATE INDEX idx_player_active ON Player(team_id) WHERE active = 1;

-- Unique index (enforces constraint)
CREATE UNIQUE INDEX idx_glossary_unique
    ON GlossaryEntry(workspace_id, source_term, target_language);
```

**Rules of thumb:**
- Index columns in WHERE, JOIN ON, ORDER BY, and GROUP BY clauses.
- Each index slows writes — only add indexes you query against.
- Composite index column order must match query filter order.
- Use `EXPLAIN QUERY PLAN` (via `driver.execute`) to verify index usage.

### FTS5 for Full-Text Search

```sql
CREATE VIRTUAL TABLE cue_fts USING fts5(text, content=Cue, content_rowid=id);

searchCues:
SELECT * FROM cue_fts WHERE cue_fts MATCH :query;
```

Requires dialect `sqlite-3-38-dialect` or newer.

### General Tips

- **Always use transactions** for batch inserts (see §6).
- **Use `INTEGER PRIMARY KEY`** to avoid redundant rowid storage (SQLite aliases it).
- **WAL + synchronous=NORMAL** (see §8).
- **`PRAGMA mmap_size=268435456`** (256 MB) for read-heavy workloads.
- **Chunk bulk operations** to respect the 999 bind-variable limit.
- **Map to domain models** — never pass generated data classes through your architecture.

---

## 11 · `generateAsync` — Suspend Queries

When `generateAsync.set(true)`:
- All generated query methods become `suspend` functions.
- Use `awaitAsList()`, `awaitAsOne()`, `awaitAsOneOrNull()` instead of `executeAs*()`.
- Schema operations: `Schema.awaitCreate(driver)`, `Schema.awaitMigrate(driver, old, new)`.

**When to enable:**
- **JS/WASM:** Required — `WebWorkerDriver` is inherently async.
- **Android/iOS/JVM:** Generally **do not enable**. The underlying SQLite I/O is blocking regardless. `suspend` wrappers are misleading — they do NOT make queries main-safe. Use `withContext(Dispatchers.IO)` instead.

**Schema type mismatch with sync drivers:** When `generateAsync = true` but using a sync driver (`AndroidSqliteDriver`, `NativeSqliteDriver`), the schema type changes to `SqlSchema<QueryResult.AsyncValue<Unit>>`. Fix by calling `.synchronous()`:

```kotlin
AndroidSqliteDriver(
    schema = AppDatabase.Schema.synchronous(),
    context = context,
    name = "app.db"
)
```

---

## 12 · Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| No code generated, no errors | Ensure `.sq` file path matches `packageName` from Gradle config |
| Duplicate query label across files | Labels must be unique module-wide. Prefix: `selectAllPlayers:`, `selectAllTeams:` |
| `last_insert_rowid()` returns wrong value on iOS | Call inside a `transaction {}` block to force the writer connection |
| In-memory DB retains data between iOS tests | Native in-memory DBs use a disc cache — create fresh driver per test |
| `Trans_history` generated class name | Use PascalCase table names: `TransHistory` |
| Migration crashes on `BEGIN TRANSACTION` | Never wrap `.sqm` content in `BEGIN/END TRANSACTION` |
| `unresolved reference: create` on generated code | Run `./gradlew generateCommonMainAppDatabaseInterface` first |
| iOS build fails linking | Add `-lsqlite3` to Xcode Other Linker Flags |
| JVM database re-creation crash ("table already exists") | Pass `schema` to `JdbcSqliteDriver` constructor (handles version checks) |
| Flow doesn't emit updates | Ensure coroutines-extensions dependency is added and you're using `asFlow()` not just `executeAsList()` |
| `generateAsync` makes queries "main-safe" | **False.** SQLite is always blocking. Use `withContext(Dispatchers.IO)` |

---

## 13 · Integration with DI (kotlin-inject)

```kotlin
// commonMain — provide the database via DI
@Inject
class DatabaseProvider(private val driverFactory: DatabaseDriverFactory) {
    fun provide(): AppDatabase {
        val driver = driverFactory.createDriver()
        configurePragmas(driver)
        return AppDatabase(driver, /* adapters */)
    }
}

// Expose query objects
@Component
abstract class DataComponent(
    @Component val platformComponent: PlatformComponent  // provides DatabaseDriverFactory
) {
    abstract val playerQueries: PlayerQueries

    @Provides fun database(provider: DatabaseProvider): AppDatabase = provider.provide()
    @Provides fun playerQueries(db: AppDatabase): PlayerQueries = db.playerQueries
}
```

---

## 14 · Integration with Ktor (Cache Pattern)

```kotlin
class SpaceRepository(
    private val api: SpaceApi,
    private val queries: LaunchQueries
) {
    suspend fun getLaunches(forceReload: Boolean): List<Launch> {
        val cached = withContext(Dispatchers.IO) {
            queries.selectAll(::mapToLaunch).executeAsList()
        }
        return if (cached.isNotEmpty() && !forceReload) {
            cached
        } else {
            val remote = api.fetchLaunches()
            withContext(Dispatchers.IO) {
                queries.transaction {
                    queries.deleteAll()
                    remote.forEach { queries.insert(/* ... */) }
                }
            }
            remote
        }
    }
}
```

---

## 15 · Delegation Map

| Topic | Delegate To |
|-------|-------------|
| Gradle build errors, version catalogue, dialect dependencies | `gradle-expert` |
| expect/actual driver factory, source set placement | `kotlin-multiplatform` |
| StateFlow/SharedFlow patterns for ViewModel layer | `kotlin-expert` |
| Advanced Flow operators (flatMapLatest, combine, stateIn) | `kotlin-coroutines` |
| kotlin-inject DI setup for driver factories | `kotlin-inject` |
| Compose UI collecting StateFlow from queries | `compose-expert` |
| Desktop file paths, app data directories | `desktop-expert` |
| Android Context, ViewModel lifecycle | `android-expert` |
