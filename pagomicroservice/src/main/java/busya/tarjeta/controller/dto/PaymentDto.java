package busya.tarjeta.controller.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import java.math.BigDecimal;

public class PaymentDto {

    @NotNull(message = "idClient no puede ser nulo")
    private Long idClient;

    @NotNull(message = "idCard no puede ser nulo")
    private Long idCard;

    @NotNull(message = "idDevice no puede ser nulo")
    private Long idDevice;

    @NotNull(message = "amount no puede ser nulo")
    @Positive(message = "amount debe ser mayor que cero")
    @DecimalMin(value = "0.01", message = "amount debe ser al menos 0.01")
    private BigDecimal amount;

    public PaymentDto() {
    }

    public PaymentDto(Long idClient, Long idCard, Long idDevice, BigDecimal amount) {
        this.idClient = idClient;
        this.idCard = idCard;
        this.idDevice = idDevice;
        this.amount = amount;
    }

    public Long getIdClient() {
        return idClient;
    }

    public void setIdClient(Long idClient) {
        this.idClient = idClient;
    }

    public Long getIdCard() {
        return idCard;
    }

    public void setIdCard(Long idCard) {
        this.idCard = idCard;
    }

    public Long getIdDevice() {
        return idDevice;
    }

    public void setIdDevice(Long idDevice) {
        this.idDevice = idDevice;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
}