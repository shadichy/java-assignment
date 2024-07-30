package vn.shadichy.assignment.provider;

import org.dizitart.no2.collection.Document;
import org.dizitart.no2.common.mapper.NitriteMapper;
import org.dizitart.no2.index.IndexType;
import org.dizitart.no2.repository.annotations.Entity;
import org.dizitart.no2.repository.annotations.Id;
import org.dizitart.no2.repository.annotations.Index;
import vn.shadichy.assignment.internal.TypeCaster;

import java.io.Serializable;
import java.util.*;

@Entity(value = "Invoice", indices = {
        @Index(fields = "tracks", type = IndexType.NON_UNIQUE),
        @Index(fields = "customer", type = IndexType.NON_UNIQUE),
        @Index(fields = "date", type = IndexType.NON_UNIQUE),
        @Index(fields = "discount", type = IndexType.NON_UNIQUE),
        @Index(fields = "trackIDs", type = IndexType.NON_UNIQUE),
})
public class Invoice extends DatabaseEntry implements Serializable {
    @Id
    private final int id;
    private final Map<Integer, Integer> tracks;
    private final int customer;
    private final Long date;
    private final Double discount;
    private final List<Integer> trackIDs;

    public Invoice(int id, Map<Integer, Integer> tracks, int customer, Long date, Double discount) {
        super(ID(id, tracks, customer, date), date);
        this.tracks = tracks;
        this.customer = customer;
        this.date = date;
        this.discount = discount;
        this.id = super.getId();
        this.trackIDs = tracks != null ? List.copyOf(tracks.keySet()) : List.of();
    }

    private static int ID(int id, Map<Integer, Integer> tracks, int customer, Long date) {
        return id != -1 ? id : Objects.hash(tracks, customer, date);
    }

    public static Invoice fromMap(Map<?, ?> invoice) {
        return new Invoice(
                -1,
                castTrack((Map<?, ?>) invoice.get("tracks")),
                TypeCaster.toInt(invoice.get("customer"), -1),
                System.currentTimeMillis() / 1000L,
                TypeCaster.toDouble(invoice.get("discount"), 0.0)
        );
    }

    private static Map<Integer, Integer> castTrack(Map<?, ?> tracks) {
        if (tracks == null) return new HashMap<>();
        return TypeCaster.castMap(tracks, TypeCaster::toInt, TypeCaster::toInt);
    }

    public Map<Integer, Integer> getTracks() {
        return tracks;
    }

    public Map<String, Object> map() {
        return new HashMap<>() {{
            put("id", id);
            put("tracks", tracks);
            put("customer", customer);
            put("date", date);
            put("discount", discount);
        }};
    }

    @Override
    public Map<String, Object> nitriteMap() {
        return new HashMap<>() {{
            putAll(map());
            put("trackIDs", trackIDs);
        }};
    }

    public static class Converter extends EntryConverter<Invoice> {
        @Override
        public Class<Invoice> getEntityType() {
            return Invoice.class;
        }

        @Override
        public Invoice fromDocument(Document document, NitriteMapper nitriteMapper) {
            return new Invoice(
                    TypeCaster.toInt(document.get("id"), -1),
                    castTrack(document.get("tracks", Map.class)),
                    TypeCaster.toInt(document.get("customer"), -1),
                    TypeCaster.toLong(document.get("date"), 0L),
                    TypeCaster.toDouble(document.get("discount"), 0.0)
            );
        }
    }
}
