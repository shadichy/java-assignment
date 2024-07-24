package vn.shadichy.assignment.provider;

import org.dizitart.no2.collection.Document;
import org.dizitart.no2.common.mapper.NitriteMapper;
import org.dizitart.no2.index.IndexType;
import org.dizitart.no2.repository.annotations.Entity;
import org.dizitart.no2.repository.annotations.Id;
import org.dizitart.no2.repository.annotations.Index;
import vn.shadichy.assignment.internal.TypeCaster;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

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
    private final Set<Integer> trackIDs;

    public Invoice(Map<Integer, Integer> tracks, int customer, Long date, Double discount) {
        super(Objects.hash(tracks, customer, date));
        this.tracks = tracks;
        this.customer = customer;
        this.date = date;
        this.discount = discount;
        this.id = super.getId();
        this.trackIDs = tracks != null ? tracks.keySet() : Set.of();
    }

    public static Invoice fromMap(Map<?, ?> invoice) {
        return new Invoice(
                castTrack((Map<?, ?>) invoice.get("tracks")),
                TypeCaster.toInt(invoice.get("customer"), -1),
                TypeCaster.toLong(invoice.get("date"), 0L),
                TypeCaster.toDouble(invoice.get("discount"), 0.0)
        );
    }

    private static Map<Integer, Integer> castTrack(Map<?, ?> tracks) {
        if (tracks == null) return new HashMap<>();
        return TypeCaster.castMap(tracks, TypeCaster::toInt, TypeCaster::toInt);
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
                    castTrack(document.get("tracks", Map.class)),
                    TypeCaster.toInt(document.get("customer"), -1),
                    TypeCaster.toLong(document.get("date"), 0L),
                    TypeCaster.toDouble(document.get("discount"), 0.0)
            );
        }
    }
}
