package vn.shadichy.assignment.internal;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

public abstract class TypeCaster {
    public static Integer toInt(Object value) {
        return toInt(value, null);
    }

    public static Integer toInt(Object value, Integer defaultValue) {
        if (value == null) return defaultValue;
        if (value instanceof String) return Integer.parseInt((String) value);
        if (value instanceof Integer) return (Integer) value;
        if (value instanceof Double) return ((Double) value).intValue();
        throw new ClassCastException("Failed to cast " + value + " to Int");
    }

    public static Long toLong(Object value) {
        return toLong(value, null);
    }

    public static Long toLong(Object value, Long defaultValue) {
        if (value == null) return defaultValue;
        if (value instanceof String) return Long.parseLong((String) value);
        if (value instanceof Long) return (Long) value;
        if (value instanceof Integer) return ((Integer) value).longValue();
        if (value instanceof Double) return ((Double) value).longValue();
        throw new ClassCastException("Failed to cast " + value + " to Long");
    }

    public static Double toDouble(Object value) {
        return toDouble(value, null);
    }

    public static Double toDouble(Object value, Double defaultValue) {
        if (value == null) return defaultValue;
        if (value instanceof String) return Double.parseDouble((String) value);
        if (value instanceof Double) return (Double) value;
        if (value instanceof Long) return ((Long) value).doubleValue();
        if (value instanceof Integer) return ((Integer) value).doubleValue();
        throw new ClassCastException("Failed to cast " + value + " to Double");
    }


    public static <K1, V1, K, V> Map<K, V> castMap(Map<K1, V1> data, Function<K1, K> keyCaster, Function<V1, V> valueCaster) {
        return new CastMap<>(data, keyCaster, valueCaster);
    }

    public static <K1, V1, K, V> Map<K, V> castMap(Map<K1, V1> data) {
        return new CastMap<>(data);
    }

    public static <T, R> List<R> castList(List<T> data, Function<T, R> caster) {
        return new CastList<>(data, caster);
    }

    public static <T, R> List<R> castList(List<T> data) {
        return new CastList<>(data);
    }

    public static class CastMap<K1, V1, K, V> extends HashMap<K, V> {
        public CastMap(Map<K1, V1> data, Function<K1, K> keyCaster, Function<V1, V> valueCaster) {
            data.forEach((key, value) -> put(keyCaster.apply(key), valueCaster.apply(value)));
        }

        public CastMap(Map<K1, V1> data) {
            this(data, k1 -> (K) k1, v1 -> (V) v1);
        }

        public <K2, V2> CastMap<K, V, K2, V2> cast(Function<K, K2> keyCaster, Function<V, V2> valueCaster) {
            return new CastMap<>(this, keyCaster, valueCaster);
        }

        public <K2, V2> CastMap<K, V, K2, V2> cast() {
            return new CastMap<>(this);
        }
    }

    public static class CastList<T, R> extends ArrayList<R> {
        public CastList(List<T> data, Function<T, R> caster) {
            data.forEach(e -> add(caster.apply(e)));
        }

        public CastList(List<T> data) {
            this(data, e -> (R) e);
        }

        public <Q> CastList<R, Q> cast(Function<R, Q> caster) {
            return new CastList<>(this, caster);
        }

        public <Q> CastList<R, Q> cast() {
            return new CastList<>(this);
        }

    }
}
