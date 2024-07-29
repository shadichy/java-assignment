package vn.shadichy.assignment.provider;

import com.google.gson.Gson;
import org.dizitart.no2.collection.Document;
import org.dizitart.no2.common.mapper.EntityConverter;
import org.dizitart.no2.common.mapper.NitriteMapper;

import java.util.Map;

interface EntryInterface {
    Map<String, Object> map();

    Map<String, Object> nitriteMap();
}

public abstract class DatabaseEntry implements EntryInterface {
    private final int id;
    private final long date;

    protected DatabaseEntry(int id, long date) {
        this.id = id;
        this.date = date;
    }

    public static String get(DatabaseEntry entry) {
        return entry.toString();
    }

    public int getId() {
        return id;
    }

    public long getDate() {
        return date;
    }

    @Override
    public String toString() {
        return new Gson().toJson(map());
    }
}

abstract class EntryConverter<T extends DatabaseEntry> implements EntityConverter<T> {
    @Override
    public Document toDocument(T entity, NitriteMapper nitriteMapper) {
        return Document.createDocument(entity.nitriteMap());
    }
}