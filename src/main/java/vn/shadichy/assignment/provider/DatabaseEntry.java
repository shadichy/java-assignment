package vn.shadichy.assignment.provider;

import com.google.gson.Gson;
import org.dizitart.no2.collection.Document;
import org.dizitart.no2.common.WriteResult;
import org.dizitart.no2.common.mapper.EntityConverter;
import org.dizitart.no2.common.mapper.NitriteMapper;
import org.dizitart.no2.repository.ObjectRepository;

import java.util.Map;

interface EntryInterface {
    Map<String, Object> map();

    Map<String, Object> nitriteMap();
}

abstract class EntryConverter<T extends DatabaseEntry> implements EntityConverter<T> {
    @Override
    public Document toDocument(T entity, NitriteMapper nitriteMapper) {
        return Document.createDocument(entity.nitriteMap());
    }
}

public abstract class DatabaseEntry implements EntryInterface {
    private final int id;
    private final long date;

    protected DatabaseEntry(int id, long date) {
        this.id = id;
        this.date = date;
    }

    public int getId() {
        return id;
    }

    public long date() {
        return date;
    }
    @Override
    public String toString() {
        return new Gson().toJson(map());
    }

    public static String get(DatabaseEntry entry) {
        return entry.toString();
    }
}
