# DSL Builder Examples

Type-safe fluent APIs and DSL patterns for KMP projects.

## FilterBuilder Pattern

```kotlin
class FilterBuilder<T> {
    private val entries = mutableMapOf<String, MutableList<Array<String>>>()

    fun add(entry: Array<String>): FilterBuilder<T> {
        if (entry.isEmpty() || entry[0].isEmpty()) return this
        entries.getOrPut(entry[0], ::mutableListOf).add(entry)
        return this
    }

    fun remove(key: String): FilterBuilder<T> {
        entries.remove(key)
        return this
    }

    fun addUnique(entry: Array<String>): FilterBuilder<T> {
        if (entry.isEmpty() || entry[0].isEmpty()) return this
        entries[entry[0]] = mutableListOf(entry)
        return this
    }

    fun addAll(list: List<Array<String>>): FilterBuilder<T> {
        list.forEach(::add)
        return this
    }

    fun build() = entries.flatMap { it.value }.toTypedArray()
}

inline fun <T> filterArray(init: FilterBuilder<T>.() -> Unit = {}): Array<Array<String>> =
    FilterBuilder<T>().apply(init).build()
```

**Usage:**
```kotlin
val filters = filterArray<DataRecord> {
    add(arrayOf("type", "note"))
    add(arrayOf("author", userId))
    addUnique(arrayOf("client", "MyApp"))
}
```

## MapOfSetBuilder

```kotlin
class MapOfSetBuilder<K, V> {
    private val map = mutableMapOf<K, MutableSet<V>>()

    fun add(key: K, value: V): MapOfSetBuilder<K, V> {
        map.getOrPut(key) { mutableSetOf() }.add(value)
        return this
    }

    fun build(): Map<K, Set<V>> = map.mapValues { it.value.toSet() }
}

inline fun <K, V> mapOfSets(init: MapOfSetBuilder<K, V>.() -> Unit): Map<K, Set<V>> =
    MapOfSetBuilder<K, V>().apply(init).build()
```

## DSL Principles

1. **Lambda with Receiver**: `FilterBuilder<T>.() -> Unit` makes `this` the builder
2. **Method Chaining**: Return `this` from mutator methods
3. **inline**: Eliminates lambda allocation overhead
4. **Validate in build()**: `require(fields.isNotEmpty())`

## Nested Builder Example

```kotlin
inline fun query(init: QueryBuilder.() -> Unit): String =
    QueryBuilder().apply(init).build()

val sql = query {
    select("id", "name")
    where {
        equals("status", "active")
        greaterThan("age", 18)
    }
    limit(10)
}
```

## Best Practices

- **DO**: Return `this`, use `inline`, provide defaults, validate in `build()`
- **DON'T**: Forget `return this`, mutate after build, expose mutable state, skip `inline`

## References

- [Type-Safe Builders | Kotlin Docs](https://kotlinlang.org/docs/type-safe-builders.html)
- [DSLs with Kotlin](https://kt.academy/article/dsl-intro)
