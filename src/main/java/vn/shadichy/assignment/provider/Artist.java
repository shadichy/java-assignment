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
import java.util.stream.Collectors;

@Entity(value = "Artist", indices = {
        @Index(fields = "name", type = IndexType.NON_UNIQUE),
        @Index(fields = "albums", type = IndexType.NON_UNIQUE),
        @Index(fields = "date", type = IndexType.NON_UNIQUE),
        @Index(fields = "description", type = IndexType.NON_UNIQUE),
        @Index(fields = "albumNames", type = IndexType.NON_UNIQUE),
        @Index(fields = "tracks", type = IndexType.NON_UNIQUE),
})
public class Artist extends DatabaseEntry implements Serializable {
    @Id
    private final int id;
    private String name;
    private Map<String, List<Integer>> albums;
    private Long date;
    private String description;
    private List<String> albumNames;
    private List<Integer> tracks;

    public Artist(int id, String name, Map<String, List<Integer>> albums, Long date, String description) {
        super(ID(id, name, date), date);
        this.id = super.getId();
        this.name = name;
        setAlbums(albums);
        this.date = date;
        this.description = description;
    }

    private static int ID(int id, String name, Long date) {
        return id != -1 ? id : Objects.hash(name, date);
    }

    public static Artist fromMap(Map<?, ?> artist) {
        return new Artist(
                TypeCaster.toInt(artist.get("id"), -1),
                (String) artist.get("name"),
                castAlbum((Map<?, ?>) artist.get("albums")),
                TypeCaster.toLong(artist.get("date"), 0L),
                (String) artist.get("description")
        );
    }

    public static Artist addNew(Map<Object, Object> artist) {
        artist.put("id", -1);
        artist.put("date", artist.get("debutDate")); // remap
        return Artist.fromMap(artist);
    }

    private static Map<String, List<Integer>> castAlbum(Map<?, ?> albums) {
        if (albums == null) return Map.of();
        return TypeCaster.castMap(albums, k -> (String) k, v -> TypeCaster.castList((List<?>) v, TypeCaster::toInt));
    }

    public void set(String name, Map<String, List<Integer>> albums, Long date, String description) {
        if (name != null) this.name = name;
        if (albums != null) this.albums = albums;
        if (date != null) this.date = date;
        if (description != null) this.description = description;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setAlbums(Map<?, ?> albums) {
        this.albums = castAlbum(albums);
        if (albums != null) {
            this.albumNames = List.copyOf(this.albums.keySet());
            this.tracks = this.albums.values().stream().flatMap(List::stream).collect(Collectors.toList());
        } else {
            this.albumNames = List.of();
            this.tracks = List.of();
        }
    }

    public void date(Long date) {
        this.date = date;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    @Override
    public Map<String, Object> map() {
        return new HashMap<>() {{
            put("id", id);
            put("name", name);
            put("albums", albums);
            put("date", date);
            put("description", description);
        }};
    }

    @Override
    public Map<String, Object> nitriteMap() {
        return new HashMap<>() {{
            putAll(map());
            put("albumNames", albumNames);
            put("tracks", tracks);
        }};
    }

    public static class Converter extends EntryConverter<Artist> {
        @Override
        public Class<Artist> getEntityType() {
            return Artist.class;
        }

        @Override
        public Artist fromDocument(Document document, NitriteMapper nitriteMapper) {
            return new Artist(
                    TypeCaster.toInt(document.get("id"), -1),
                    document.get("name", String.class),
                    castAlbum(document.get("albums", Map.class)),
                    TypeCaster.toLong(document.get("date"), 0L),
                    document.get("description", String.class)
            );
        }
    }
}
