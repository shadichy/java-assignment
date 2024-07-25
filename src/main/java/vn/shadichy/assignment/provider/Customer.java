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

@Entity(value = "Customer", indices = {
        @Index(fields = "name", type = IndexType.NON_UNIQUE),
        @Index(fields = "phoneNo", type = IndexType.NON_UNIQUE),
        @Index(fields = "date", type = IndexType.NON_UNIQUE),
        @Index(fields = "email", type = IndexType.NON_UNIQUE),
})
public class Customer extends DatabaseEntry implements Serializable {
    @Id
    private final int id;
    private String name;
    private List<String> phoneNo;
    private Long date;
    private String email;

    public Customer(int id, String name, List<String> phoneNo, Long date, String email) {
        super(ID(id, name, phoneNo, date, email), date);
        this.id = super.getId();
        this.name = name;
        this.phoneNo = phoneNo;
        this.date = date;
        this.email = email;
    }

    public static int ID(int id, String name, List<String> phoneNo, Long date, String email) {
        return id != -1 ? id : Objects.hash(name, phoneNo, date, email);
    }

    public static Customer fromMap(Map<?, ?> customer) {
        return new Customer(
                TypeCaster.toInt(customer.get("id"), -1),
                (String) customer.get("name"),
                (List) customer.get("phoneNo"),
                TypeCaster.toLong(customer.get("date"), 0L),
                (String) customer.get("email")
        );
    }

    public static Customer addNew(Map<Object, Object> customer) {
        customer.put("id", -1);
        customer.put("date", customer.get("createdDate"));
        return Customer.fromMap(customer);
    }

    public void set(String name, List<String> phoneNo, Long date, String email) {
        if (name != null) this.name = name;
        if (phoneNo != null) this.phoneNo = phoneNo;
        if (date != null) this.date = date;
        if (email != null) this.email = email;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setPhoneNo(List<String> phoneNo) {
        this.phoneNo = phoneNo;
    }

    public void date(Long date) {
        this.date = date;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    @Override
    public Map<String, Object> map() {
        return new HashMap<>() {{
            put("id", id);
            put("name", name);
            put("phoneNo", phoneNo);
            put("date", date);
            put("email", email);
        }};
    }

    @Override
    public Map<String, Object> nitriteMap() {
        return map();
    }

    public static class Converter extends EntryConverter<Customer> {
        @Override
        public Class<Customer> getEntityType() {
            return Customer.class;
        }

        @Override
        public Customer fromDocument(Document document, NitriteMapper nitriteMapper) {
            return new Customer(
                    TypeCaster.toInt(document.get("id"), -1),
                    document.get("name", String.class),
                    document.get("phoneNo", List.class),
                    TypeCaster.toLong(document.get("date"), 0L),
                    document.get("email", String.class)
            );
        }
    }
}
