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
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Entity(value = "Disc", indices = {
        @Index(fields = "name", type = IndexType.NON_UNIQUE),
        @Index(fields = "releaseDate", type = IndexType.NON_UNIQUE),
        @Index(fields = "artists", type = IndexType.NON_UNIQUE),
        @Index(fields = "stockCount", type = IndexType.NON_UNIQUE),
        @Index(fields = "price", type = IndexType.NON_UNIQUE),
        @Index(fields = "image", type = IndexType.NON_UNIQUE),
})
public class Disc extends DatabaseEntry implements Serializable {
    @Id
    private final int id;
    private String name;
    private Long releaseDate;
    private List<Integer> artists;
    private Integer stockCount;
    private Double price;
    private String image;

    public Disc(int id, String name, Long releaseDate, List<Integer> artists, Integer stockCount, Double price, String image) {
        super(ID(id, name, releaseDate, artists));
        this.id = super.getId();
        this.name = name;
        this.releaseDate = releaseDate;
        this.artists = artists;
        this.stockCount = stockCount;
        this.price = price;
        this.image = image;
    }

    private static int ID(int id, String name, Long releaseDate, List<Integer> artists) {
        return id != -1 ? id : Objects.hash(name, releaseDate, artists);
    }

    public static Disc fromMap(Map<?, ?> disc) {
        return new Disc(
                TypeCaster.toInt(disc.get("id"), -1),
                (String) disc.get("name"),
                TypeCaster.toLong(disc.get("releaseDate"), 0L),
                castArtist((List<?>) disc.get("artists")),
                TypeCaster.toInt(disc.get("stockCount"), 0),
                TypeCaster.toDouble(disc.get("price"), 0.0),
                (String) disc.get("image")
        );
    }

    public static Disc addNew(Map<Object, Object> disc) {
        disc.put("id", -1);
        return Disc.fromMap(disc);
    }

    private static List<Integer> castArtist(List<?> artists) {
        if (artists == null) return List.of();
        return TypeCaster.castList(artists, TypeCaster::toInt);
    }

    public void set(String name, Long releaseDate, List<Integer> artists, Integer stockCount, Double price, String image) {
        if (name != null) this.name = name;
        if (releaseDate != null) this.releaseDate = releaseDate;
        if (artists != null) this.artists = artists;
        if (stockCount != null) this.stockCount = stockCount;
        if (price != null) this.price = price;
        if (image != null) this.image = image;
    }

    public int hash() {
        return Objects.hash(this.name, this.releaseDate, this.artists);
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setReleaseDate(Long releaseDate) {
        this.releaseDate = releaseDate;
    }

    public void setArtists(List<?> artists) {
        this.artists = TypeCaster.castList(artists, TypeCaster::toInt);
    }

    public void setStockCount(Integer stockCount) {
        this.stockCount = stockCount;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public void setImage(String image) {
        this.image = image;
    }

    @Override
    public Map<String, Object> map() {
        return new HashMap<>() {{
            put("id", id);
            put("name", name);
            put("releaseDate", releaseDate);
            put("artists", artists);
            put("stockCount", stockCount);
            put("price", price);
            put("image", image);
        }};
    }

    @Override
    public Map<String, Object> nitriteMap() {
        return map();
    }

    public static class Converter extends EntryConverter<Disc> {
        @Override
        public Class<Disc> getEntityType() {
            return Disc.class;
        }

        @Override
        public Disc fromDocument(Document document, NitriteMapper nitriteMapper) {
            return new Disc(
                    TypeCaster.toInt(document.get("id"), -1),
                    document.get("name", String.class),
                    TypeCaster.toLong(document.get("releaseDate"), 0L),
                    castArtist(document.get("artists", List.class)),
                    TypeCaster.toInt(document.get("stockCount"), 0),
                    TypeCaster.toDouble(document.get("price"), 0.0),
                    document.get("image", String.class)
            );
        }
    }
}
