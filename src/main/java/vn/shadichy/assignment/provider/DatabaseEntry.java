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

    protected DatabaseEntry(int id) {
        this.id = id;
    }

    public int getId() {
        return id;
    }
    @Override
    public String toString() {
        return new Gson().toJson(map());
    }

    public static String get(DatabaseEntry entry) {
        return entry.toString();
    }
}
